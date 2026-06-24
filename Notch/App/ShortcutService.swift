import AppKit
import Carbon.HIToolbox

final class ShortcutService {
    var onToggle: (() -> Void)?
    var onDismiss: (() -> Void)?

    private static let signature: OSType = 0x4E_54_43_48 // NTCH
    private static let toggleID: UInt32 = 1
    private static let dismissID: UInt32 = 2

    private var eventHandler: EventHandlerRef?
    private var toggleHotKey: EventHotKeyRef?
    private var dismissHotKey: EventHotKeyRef?

    func start() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.handleHotKey,
            1,
            &eventType,
            pointer,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.toggleID)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &toggleHotKey
        )
    }

    func setDismissShortcutEnabled(_ enabled: Bool) {
        if enabled, dismissHotKey == nil {
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.dismissID)
            RegisterEventHotKey(
                UInt32(kVK_Escape),
                0,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &dismissHotKey
            )
        } else if !enabled, let dismissHotKey {
            UnregisterEventHotKey(dismissHotKey)
            self.dismissHotKey = nil
        }
    }

    func stop() {
        if let toggleHotKey {
            UnregisterEventHotKey(toggleHotKey)
            self.toggleHotKey = nil
        }
        if let dismissHotKey {
            UnregisterEventHotKey(dismissHotKey)
            self.dismissHotKey = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private static let handleHotKey: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr, hotKeyID.signature == ShortcutService.signature else {
            return OSStatus(eventNotHandledErr)
        }

        let service = Unmanaged<ShortcutService>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
            switch hotKeyID.id {
            case ShortcutService.toggleID:
                service.onToggle?()
            case ShortcutService.dismissID:
                service.onDismiss?()
            default:
                break
            }
        }
        return noErr
    }
}
