import AppKit
import Foundation
import IOBluetooth
import IOKit

enum BluetoothDeviceCategory: String, Sendable {
    case computer
    case phone
    case network
    case audio
    case keyboard
    case pointingDevice
    case keyboardAndPointingDevice
    case peripheral
    case imaging
    case wearable
    case toy
    case health
    case unknown
}

struct BluetoothDevice: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
    let category: BluetoothDeviceCategory
    let isRemembered: Bool
    let isAvailable: Bool
    let isConnected: Bool
    /// `nil` means that macOS/the device does not publish a battery percentage.
    let batteryLevel: Int?
    let lastSeenAt: Date?
}

struct BluetoothDeviceEvent: Sendable {
    enum Kind: Sendable {
        case connected
        case disconnected
        case batteryLevelChanged
        case becameAvailable
        case becameUnavailable
    }

    let kind: Kind
    let device: BluetoothDevice
    let previousDevice: BluetoothDevice?
}

extension Notification.Name {
    static let bluetoothDevicesDidChange = Notification.Name("BluetoothDeviceService.devicesDidChange")
    static let bluetoothDeviceEvent = Notification.Name("BluetoothDeviceService.deviceEvent")
}

enum BluetoothDeviceNotificationKey {
    static let devices = "devices"
    static let event = "event"
}

protocol BluetoothDeviceServiceProtocol: AnyObject {
    var devices: [BluetoothDevice] { get }
    var rememberedDevices: [BluetoothDevice] { get }
    var availableDevices: [BluetoothDevice] { get }
    var connectedDevices: [BluetoothDevice] { get }
    var isDiscovering: Bool { get }

    func start()
    func stop()
    func refresh()
    func startDiscovery(duration: TimeInterval)
    func stopDiscovery()
    func fetchRememberedAudioDevices() -> [BluetoothDevice]
    func connectDevice(_ device: BluetoothDevice, completion: @escaping (Bool) -> Void)
}

final class BluetoothDeviceService: NSObject, BluetoothDeviceServiceProtocol {
    static let shared = BluetoothDeviceService()

    private(set) var devices: [BluetoothDevice] = []
    private(set) var isDiscovering = false

    var rememberedDevices: [BluetoothDevice] {
        devices.filter(\.isRemembered)
    }

    var availableDevices: [BluetoothDevice] {
        devices.filter(\.isAvailable)
    }

    var connectedDevices: [BluetoothDevice] {
        devices.filter(\.isConnected)
    }

    private let batteryRefreshInterval: TimeInterval = 15

    private var isStarted = false
    private var isRefreshing = false
    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]
    private var batteryTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var inquiry: IOBluetoothDeviceInquiry?

    private var rawDevices: [String: IOBluetoothDevice] = [:]
    private var discoveredDeviceIDs = Set<String>()
    private var pendingDiscoveredDeviceIDs = Set<String>()
    private var connectedDeviceIDs = Set<String>()
    private var lastSeenDates: [String: Date] = [:]

    private override init() {
        super.init()
    }

    func start() {
        performOnMain { [weak self] in
            guard let self, !self.isStarted else { return }
            self.isStarted = true
            self.connectNotification = IOBluetoothDevice.register(
                forConnectNotifications: self,
                selector: #selector(self.deviceConnected(_:device:))
            )
            self.wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refresh()
                self?.startDiscovery(duration: 8)
            }
            self.batteryTimer = Timer.scheduledTimer(
                withTimeInterval: self.batteryRefreshInterval,
                repeats: true
            ) { [weak self] _ in
                self?.refresh()
            }
            self.refreshOnMain()
            self.startDiscoveryOnMain(duration: 8)
        }
    }

    func stop() {
        performOnMain { [weak self] in
            guard let self, self.isStarted else { return }
            self.isStarted = false
            self.stopDiscoveryOnMain()
            self.connectNotification?.unregister()
            self.connectNotification = nil
            self.disconnectNotifications.values.forEach { $0.unregister() }
            self.disconnectNotifications.removeAll()
            self.batteryTimer?.invalidate()
            self.batteryTimer = nil
            if let wakeObserver = self.wakeObserver {
                NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
                self.wakeObserver = nil
            }
        }
    }

    func refresh() {
        performOnMain { [weak self] in
            self?.refreshOnMain()
        }
    }

    func startDiscovery(duration: TimeInterval = 8) {
        performOnMain { [weak self] in
            self?.startDiscoveryOnMain(duration: duration)
        }
    }

    func stopDiscovery() {
        performOnMain { [weak self] in
            self?.stopDiscoveryOnMain()
        }
    }

    func fetchRememberedAudioDevices() -> [BluetoothDevice] {
        return rememberedDevices.filter { $0.category == .audio }
    }

    func connectDevice(_ device: BluetoothDevice, completion: @escaping (Bool) -> Void) {
        performOnMain { [weak self] in
            guard let self,
                  let rawDevice = self.rawDevice(for: device) else {
                completion(false)
                return
            }

            guard !rawDevice.isConnected() else {
                completion(true)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let status = rawDevice.openConnection()
                DispatchQueue.main.async {
                    self?.refreshOnMain()
                    completion(status == kIOReturnSuccess)
                }
            }
        }
    }

    deinit {
        connectNotification?.unregister()
        disconnectNotifications.values.forEach { $0.unregister() }
        batteryTimer?.invalidate()
    }

    @objc private func deviceConnected(
        _ notification: IOBluetoothUserNotification,
        device: IOBluetoothDevice
    ) {
        performOnMain { [weak self] in
            guard let self else { return }
            let id = self.id(for: device)
            self.rawDevices[id] = device
            self.connectedDeviceIDs.insert(id)
            self.lastSeenDates[id] = Date()
            self.refreshOnMain()
        }
    }

    @objc private func deviceDisconnected(
        _ notification: IOBluetoothUserNotification,
        device: IOBluetoothDevice
    ) {
        performOnMain { [weak self] in
            guard let self else { return }
            self.connectedDeviceIDs.remove(self.id(for: device))
            self.refreshOnMain()
        }
    }

    private func startDiscoveryOnMain(duration: TimeInterval) {
        guard !isDiscovering else { return }

        guard let inquiry = IOBluetoothDeviceInquiry(delegate: self) else { return }
        inquiry.inquiryLength = UInt8(max(1, min(duration, 48)))
        inquiry.searchType = UInt32(kIOBluetoothDeviceSearchClassic.rawValue)
            | UInt32(kIOBluetoothDeviceSearchLE.rawValue)
        inquiry.updateNewDeviceNames = true
        pendingDiscoveredDeviceIDs.removeAll()

        let status = inquiry.start()
        guard status == kIOReturnSuccess else { return }

        self.inquiry = inquiry
        isDiscovering = true
    }

    private func stopDiscoveryOnMain() {
        guard let inquiry else { return }
        _ = inquiry.stop()
        self.inquiry = nil
        isDiscovering = false
    }

    private func refreshOnMain() {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let previousDevices = devices
        let batteryReadings = readBatteryReadings()
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        let connectedRecent = ((IOBluetoothDevice.recentDevices(0) as? [IOBluetoothDevice]) ?? [])
            .filter { $0.isConnected() }

        var candidates: [String: IOBluetoothDevice] = [:]
        for device in paired + connectedRecent {
            candidates[id(for: device)] = device
        }
        for id in discoveredDeviceIDs {
            if let device = rawDevices[id] {
                candidates[id] = device
            }
        }
        for id in connectedDeviceIDs {
            if let device = rawDevices[id] {
                candidates[id] = device
            }
        }

        let now = Date()
        for (id, device) in candidates {
            rawDevices[id] = device
            if device.isConnected(), lastSeenDates[id] == nil {
                lastSeenDates[id] = now
            }
        }
        connectedDeviceIDs = Set(candidates.compactMap { id, device in
            device.isConnected() ? id : nil
        })

        let updatedDevices = candidates.values
            .map { makeDevice(from: $0, batteryReadings: batteryReadings) }
            .sorted(by: deviceSort)

        devices = updatedDevices
        updateDisconnectNotifications(for: candidates)
        publishChanges(from: previousDevices, to: updatedDevices)
    }

    private func makeDevice(
        from device: IOBluetoothDevice,
        batteryReadings: BatteryReadings
    ) -> BluetoothDevice {
        let address = device.addressString ?? ""
        let id = id(for: device)
        let name = device.name ?? device.nameOrAddress ?? "Unknown device"
        let batteryLevel = batteryReadings.byAddress[normalizeAddress(address)]
            ?? batteryReadings.byName[normalizeName(name)]

        return BluetoothDevice(
            id: id,
            name: name,
            address: address,
            category: category(for: device),
            isRemembered: device.isPaired(),
            isAvailable: device.isConnected() || discoveredDeviceIDs.contains(id),
            isConnected: device.isConnected(),
            batteryLevel: batteryLevel,
            lastSeenAt: lastSeenDates[id]
        )
    }

    private func updateDisconnectNotifications(for candidates: [String: IOBluetoothDevice]) {
        let connectedIDs = Set(candidates.compactMap { id, device in
            device.isConnected() ? id : nil
        })

        let staleNotificationIDs = disconnectNotifications.keys.filter {
            !connectedIDs.contains($0)
        }
        for id in staleNotificationIDs {
            disconnectNotifications[id]?.unregister()
            disconnectNotifications[id] = nil
        }

        for id in connectedIDs where disconnectNotifications[id] == nil {
            disconnectNotifications[id] = candidates[id]?.register(
                forDisconnectNotification: self,
                selector: #selector(deviceDisconnected(_:device:))
            )
        }
    }

    private func publishChanges(
        from previousDevices: [BluetoothDevice],
        to updatedDevices: [BluetoothDevice]
    ) {
        guard previousDevices != updatedDevices else { return }

        let previousByID = Dictionary(uniqueKeysWithValues: previousDevices.map { ($0.id, $0) })
        let updatedByID = Dictionary(uniqueKeysWithValues: updatedDevices.map { ($0.id, $0) })
        let allIDs = Set(previousByID.keys).union(updatedByID.keys)

        for id in allIDs {
            let previous = previousByID[id]
            let updated = updatedByID[id]
            let connectionChanged = previous?.isConnected != updated?.isConnected

            if connectionChanged {
                if let updated, updated.isConnected {
                    publishEvent(.connected, device: updated, previous: previous)
                } else if let previous, previous.isConnected {
                    publishEvent(
                        .disconnected,
                        device: disconnectedCopy(of: previous),
                        previous: previous
                    )
                }
            }

            if !connectionChanged,
               let updated,
               previous?.batteryLevel != updated.batteryLevel,
               previous != nil {
                publishEvent(.batteryLevelChanged, device: updated, previous: previous)
            }

            if !connectionChanged,
               previous?.isAvailable != updated?.isAvailable {
                if let updated, updated.isAvailable {
                    publishEvent(.becameAvailable, device: updated, previous: previous)
                } else if let previous, previous.isAvailable {
                    publishEvent(
                        .becameUnavailable,
                        device: unavailableCopy(of: previous),
                        previous: previous
                    )
                }
            }
        }

        NotificationCenter.default.post(
            name: .bluetoothDevicesDidChange,
            object: self,
            userInfo: [BluetoothDeviceNotificationKey.devices: updatedDevices]
        )
    }

    private func publishEvent(
        _ kind: BluetoothDeviceEvent.Kind,
        device: BluetoothDevice,
        previous: BluetoothDevice?
    ) {
        let event = BluetoothDeviceEvent(
            kind: kind,
            device: device,
            previousDevice: previous
        )
        NotificationCenter.default.post(
            name: .bluetoothDeviceEvent,
            object: self,
            userInfo: [BluetoothDeviceNotificationKey.event: event]
        )
    }

    private func rawDevice(for device: BluetoothDevice) -> IOBluetoothDevice? {
        if let rawDevice = rawDevices[device.id] {
            return rawDevice
        }
        return (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice])?
            .first { id(for: $0) == device.id }
    }

    private func id(for device: IOBluetoothDevice) -> String {
        let address = normalizeAddress(device.addressString ?? "")
        if !address.isEmpty {
            return address
        }
        return "name:\(normalizeName(device.nameOrAddress ?? "unknown"))"
    }

    private func category(for device: IOBluetoothDevice) -> BluetoothDeviceCategory {
        switch device.deviceClassMajor {
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorComputer):
            return .computer
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorPhone):
            return .phone
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorLANAccessPoint):
            return .network
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorAudio):
            return .audio
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorPeripheral):
            switch device.deviceClassMinor & 0x30 {
            case 0x10: return .keyboard
            case 0x20: return .pointingDevice
            case 0x30: return .keyboardAndPointingDevice
            default: return .peripheral
            }
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorImaging):
            return .imaging
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorWearable):
            return .wearable
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorToy):
            return .toy
        case BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorHealth):
            return .health
        default:
            return .unknown
        }
    }

    private func deviceSort(_ lhs: BluetoothDevice, _ rhs: BluetoothDevice) -> Bool {
        if lhs.isConnected != rhs.isConnected { return lhs.isConnected }
        if lhs.isAvailable != rhs.isAvailable { return lhs.isAvailable }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func disconnectedCopy(of device: BluetoothDevice) -> BluetoothDevice {
        BluetoothDevice(
            id: device.id,
            name: device.name,
            address: device.address,
            category: device.category,
            isRemembered: device.isRemembered,
            isAvailable: device.isAvailable,
            isConnected: false,
            batteryLevel: device.batteryLevel,
            lastSeenAt: device.lastSeenAt
        )
    }

    private func unavailableCopy(of device: BluetoothDevice) -> BluetoothDevice {
        BluetoothDevice(
            id: device.id,
            name: device.name,
            address: device.address,
            category: device.category,
            isRemembered: device.isRemembered,
            isAvailable: false,
            isConnected: device.isConnected,
            batteryLevel: device.batteryLevel,
            lastSeenAt: device.lastSeenAt
        )
    }

    private func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}

extension BluetoothDeviceService: IOBluetoothDeviceInquiryDelegate {
    func deviceInquiryDeviceFound(
        _ sender: IOBluetoothDeviceInquiry,
        device: IOBluetoothDevice
    ) {
        performOnMain { [weak self] in
            guard let self else { return }
            let id = self.id(for: device)
            self.rawDevices[id] = device
            self.pendingDiscoveredDeviceIDs.insert(id)
            self.lastSeenDates[id] = Date()
        }
    }

    func deviceInquiryComplete(
        _ sender: IOBluetoothDeviceInquiry,
        error: IOReturn,
        aborted: Bool
    ) {
        performOnMain { [weak self] in
            guard let self else { return }
            if !aborted && error == kIOReturnSuccess {
                self.discoveredDeviceIDs = self.pendingDiscoveredDeviceIDs
            }
            self.pendingDiscoveredDeviceIDs.removeAll()
            self.inquiry = nil
            self.isDiscovering = false
            self.refreshOnMain()
        }
    }
}

private extension BluetoothDeviceService {
    struct BatteryReadings {
        var byAddress: [String: Int] = [:]
        var byName: [String: Int] = [:]
    }

    func readBatteryReadings() -> BatteryReadings {
        let serviceClasses = [
            "IOHIDDevice",
            "AppleDeviceManagementHIDEventService",
            "AppleBluetoothHIDKeyboard",
            "BNBMouseDevice",
            "AppleHSBluetoothDevice"
        ]
        var readings = BatteryReadings()

        for serviceClass in serviceClasses {
            guard let matching = IOServiceMatching(serviceClass) else { continue }
            var iterator: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
                continue
            }
            defer { IOObjectRelease(iterator) }

            while case let service = IOIteratorNext(iterator), service != 0 {
                defer { IOObjectRelease(service) }
                let transport = registryString(service, keys: ["Transport"])
                if let transport,
                   !transport.localizedCaseInsensitiveContains("bluetooth") {
                    continue
                }

                guard let batteryLevel = registryInt(
                    service,
                    keys: ["BatteryPercent", "CurrentBatteryPercent", "BatteryLevel"]
                ) else {
                    continue
                }

                let normalizedLevel = max(0, min(batteryLevel, 100))
                if let address = registryString(
                    service,
                    keys: ["DeviceAddress", "BluetoothDeviceAddress", "Address"]
                ) {
                    readings.byAddress[normalizeAddress(address)] = normalizedLevel
                }
                if let name = registryString(
                    service,
                    keys: ["Product", "ProductName", "DeviceName"]
                ) {
                    readings.byName[normalizeName(name)] = normalizedLevel
                }
            }
        }

        return readings
    }

    func registryInt(_ service: io_registry_entry_t, keys: [String]) -> Int? {
        for key in keys {
            guard let value = registryValue(service, key: key) else { continue }
            if let number = value as? NSNumber {
                return number.intValue
            }
            if let string = value as? String, let integer = Int(string) {
                return integer
            }
            if let data = value as? Data, let byte = data.first {
                return Int(byte)
            }
        }
        return nil
    }

    func registryString(_ service: io_registry_entry_t, keys: [String]) -> String? {
        for key in keys {
            if let string = registryValue(service, key: key) as? String, !string.isEmpty {
                return string
            }
        }
        return nil
    }

    func registryValue(_ service: io_registry_entry_t, key: String) -> Any? {
        return IORegistryEntrySearchCFProperty(
            service,
            kIOServicePlane,
            key as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        )
    }

    func normalizeAddress(_ address: String) -> String {
        address.lowercased().filter(\.isHexDigit)
    }

    func normalizeName(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
