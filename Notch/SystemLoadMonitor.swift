import Combine
import Darwin.Mach
import Foundation

struct SystemLoadSnapshot {
    let cpuLoad: Double
    let memoryLoad: Double

    static let empty = SystemLoadSnapshot(cpuLoad: 0, memoryLoad: 0)
}

@MainActor
final class SystemLoadMonitor: NSObject, ObservableObject {
    @Published private(set) var snapshot = SystemLoadSnapshot.empty

    private var sampler = SystemLoadSampler()
    private var timer: Timer?

    override init() {
        super.init()
        refresh()

        let timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(handleTimer(_:)),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = 0.2
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
    }

    private func refresh() {
        snapshot = sampler.snapshot()
    }

    @objc private func handleTimer(_ timer: Timer) {
        refresh()
    }
}

private struct SystemLoadSampler {
    private var previousCPUTicks: CPUTicks?

    mutating func snapshot() -> SystemLoadSnapshot {
        SystemLoadSnapshot(
            cpuLoad: cpuLoad() ?? 0,
            memoryLoad: Self.memoryLoad() ?? 0
        )
    }

    private mutating func cpuLoad() -> Double? {
        guard let currentTicks = Self.cpuTicks() else { return nil }
        defer { previousCPUTicks = currentTicks }

        guard let previousCPUTicks else { return 0 }

        let userDelta = currentTicks.user - previousCPUTicks.user
        let systemDelta = currentTicks.system - previousCPUTicks.system
        let idleDelta = currentTicks.idle - previousCPUTicks.idle
        let niceDelta = currentTicks.nice - previousCPUTicks.nice
        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

        guard totalDelta > 0 else { return 0 }

        let activeDelta = totalDelta - idleDelta
        return Self.clamped(Double(activeDelta) / Double(totalDelta))
    }

    private static func cpuTicks() -> CPUTicks? {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        return CPUTicks(
            user: UInt64(cpuInfo.cpu_ticks.0),
            system: UInt64(cpuInfo.cpu_ticks.1),
            idle: UInt64(cpuInfo.cpu_ticks.2),
            nice: UInt64(cpuInfo.cpu_ticks.3)
        )
    }

    private static func memoryLoad() -> Double? {
        var vmInfo = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(vmInfo.active_count)
            + UInt64(vmInfo.wire_count)
            + UInt64(vmInfo.compressor_page_count)
        let usedBytes = usedPages * pageSize
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        guard totalBytes > 0 else { return nil }

        return clamped(Double(usedBytes) / Double(totalBytes))
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct CPUTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64
}
