
//
//  FloatingNotificationPanel.swift
//

import AppKit

final class FloatingNotificationPanel: NSPanel {

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
