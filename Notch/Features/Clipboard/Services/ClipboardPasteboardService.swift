import AppKit
import ApplicationServices
import Foundation

extension Notification.Name {
    static let clipboardWillPaste = Notification.Name("NotchClipboardWillPaste")
}

final class ClipboardPasteboardService {
    var onCapture: ((ClipboardCapture) -> Void)?

    private let reader = ClipboardPasteboardReader()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoredExactHash: String?
    private var pasteTargetApplication: NSRunningApplication?

    var canPasteAutomatically: Bool {
        AXIsProcessTrusted()
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func copy(_ capture: ClipboardCapture) {
        restore(capture)
    }

    func paste(_ capture: ClipboardCapture) -> Bool {
        restore(capture)

        guard canPasteAutomatically else {
            requestAccessibilityPermission()
            return false
        }

        NotificationCenter.default.post(name: .clipboardWillPaste, object: nil)
        postPasteShortcutWhenReady()
        return true
    }

    func rememberPasteTarget() {
        rememberFrontmostApplication()
    }

    func requestAccessibilityPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    private func pollPasteboard() {
        rememberFrontmostApplication()

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let capture = reader.readCapture(from: pasteboard) else {
            return
        }

        if capture.exactHash == ignoredExactHash {
            ignoredExactHash = nil
            return
        }

        onCapture?(capture)
    }

    private func restore(_ capture: ClipboardCapture) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let pasteboardItems = capture.items.map { clipboardItem in
            let pasteboardItem = NSPasteboardItem()
            for representation in clipboardItem.representations {
                pasteboardItem.setData(representation.data, forType: representation.pasteboardType)
            }
            return pasteboardItem
        }

        pasteboard.writeObjects(pasteboardItems)
        lastChangeCount = pasteboard.changeCount
        ignoredExactHash = capture.exactHash
    }

    private func postPasteShortcutWhenReady() {
        if let pasteTargetApplication, !pasteTargetApplication.isTerminated {
            NSApp.yieldActivation(to: pasteTargetApplication)
            pasteTargetApplication.activate(from: .current, options: [])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
                self?.postPasteShortcut()
            }
        } else {
            NSApp.deactivate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.postPasteShortcut()
            }
        }
    }

    private func postPasteShortcut() {
        let vKeyCode: CGKeyCode = 9
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func rememberFrontmostApplication() {
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.processIdentifier != NSRunningApplication.current.processIdentifier else {
            return
        }
        pasteTargetApplication = application
    }
}
