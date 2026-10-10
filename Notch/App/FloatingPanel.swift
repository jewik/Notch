
//
//  FloatingNotificationPanel.swift
//

import AppKit

final class FloatingPanel: NSPanel {

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
    
    @objc func _hasActiveAppearanceIgnoringKeyFocus() -> Bool { true }
}
