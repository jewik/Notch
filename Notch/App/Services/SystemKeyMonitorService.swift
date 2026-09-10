import AppKit
import CoreGraphics
import Carbon.HIToolbox

final class SystemKeyMonitorService {

    enum Action {
        case brightnessDown
        case brightnessUp
        case volumeDown
        case volumeUp
        case mute
    }

    var onAction: ((Action) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // NX_SYSDEFINED is not represented by a CGEventType case.
    // It is the system-defined event type used for media keys.
    private static let systemDefinedEventType = UInt32(NX_SYSDEFINED)

    // MARK: - Start

    func start() {
        guard eventTap == nil else {
            return
        }

        let eventMask: CGEventMask =
            CGEventMask(1) << CGEventMask(Self.systemDefinedEventType)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in

                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let service = Unmanaged<SystemKeyMonitorService>
                    .fromOpaque(refcon)
                    .takeUnretainedValue()

                return service.handle(
                    proxy: proxy,
                    type: type,
                    event: event
                )
            },
            userInfo: refcon
        ) else {
            print("❌ Failed to create CGEvent tap")
            print("   Check Accessibility permission.")
            return
        }

        eventTap = tap

        guard let source = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            tap,
            0
        ) else {
            print("❌ Failed to create run loop source")

            CGEvent.tapEnable(
                tap: tap,
                enable: false
            )

            eventTap = nil

            return
        }

        runLoopSource = source

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            source,
            .commonModes
        )

        CGEvent.tapEnable(
            tap: tap,
            enable: true
        )

        print("✅ SystemKeyMonitor started")
    }

    // MARK: - Stop

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(
                tap: eventTap,
                enable: false
            )
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        eventTap = nil
        runLoopSource = nil

        print("🛑 SystemKeyMonitor stopped")
    }

    // MARK: - Event handling

    private func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {

        // CGEventType does NOT have .systemDefined.
        //
        // Compare the raw value with NX_SYSDEFINED instead.
        guard type.rawValue == Self.systemDefinedEventType else {
            return Unmanaged.passUnretained(event)
        }

        guard let action = action(from: event) else {
            return Unmanaged.passUnretained(event)
        }

        Task { @MainActor [weak self] in
            self?.onAction?(action)
        }

        // IMPORTANT:
        //
        // Returning nil removes the event from the event stream.
        //
        // Therefore macOS does not receive the volume/brightness
        // key event and its standard HUD/action is not triggered.
        return nil
    }

    // MARK: - Decode media key

    private func action(
        from event: CGEvent
    ) -> Action? {

        guard let nsEvent = NSEvent(cgEvent: event) else {
            return nil
        }

        guard nsEvent.type == .systemDefined else {
            return nil
        }

        // Media keys are represented as system-defined events.
        guard nsEvent.subtype == .screenChanged else {
            return nil
        }

        let data1 = nsEvent.data1

        // The high 16 bits contain the NX key type.
        let keyCode = Int32(
            (data1 >> 16) & 0xFFFF
        )

        // Bits 8...15 contain key state.
        let keyState = Int32(
            (data1 >> 8) & 0xFF
        )

        // 0xA = key down
        // 0xB = key up
        //
        // We only want to react once when the key is pressed.
        guard keyState == 0xA else {
            return nil
        }

        switch keyCode {

        case NX_KEYTYPE_BRIGHTNESS_DOWN:
            return .brightnessDown

        case NX_KEYTYPE_BRIGHTNESS_UP:
            return .brightnessUp

        case NX_KEYTYPE_SOUND_DOWN:
            return .volumeDown

        case NX_KEYTYPE_SOUND_UP:
            return .volumeUp

        case NX_KEYTYPE_MUTE:
            return .mute

        default:
            return nil
        }
    }

    deinit {
        // `SystemKeyMonitorService` is deliberately NOT @MainActor,
        // so deinit can safely perform this cleanup.
        stop()
    }
}
