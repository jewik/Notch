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
        guard let text = directPasteText(for: capture), !text.isEmpty else {
            return false
        }

        guard canPasteAutomatically else {
            requestAccessibilityPermission()
            return false
        }

        NotificationCenter.default.post(name: .clipboardWillPaste, object: nil)
        directInsert(text)
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

    private func directPasteText(for capture: ClipboardCapture) -> String? {
        if let text = capture.primaryTextRepresentation?.decodedText {
            return text
        }
        return capture.items
            .flatMap(\.representations)
            .first(where: { $0.isPlainText })?
            .decodedText
    }

    private func directInsert(_ text: String) {
        let insert: () -> Void = { [weak self] in
            guard let self else { return }
            postUnicodeText(text)
        }

        if let pasteTargetApplication, !pasteTargetApplication.isTerminated {
            NSApp.yieldActivation(to: pasteTargetApplication)
            pasteTargetApplication.activate(from: .current, options: [])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: insert)
        } else {
            NSApp.deactivate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: insert)
        }
    }

    private func postUnicodeText(_ text: String) {
        var chunk = ""
        var characterCount = 0

        for character in text {
            chunk.append(character)
            characterCount += 1

            if characterCount >= 16 {
                postUnicodeChunk(chunk)
                chunk.removeAll(keepingCapacity: true)
                characterCount = 0
            }
        }

        if !chunk.isEmpty {
            postUnicodeChunk(chunk)
        }
    }

    private func postUnicodeChunk(_ text: String) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return
        }

        var utf16 = Array(text.utf16)
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
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
