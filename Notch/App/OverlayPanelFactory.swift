
//  OverlayPanelFactory.swift
//

import AppKit
//import SwiftUI

enum OverlayWindowLevel {
    static let interactiveNotch = NSWindow.Level.mainMenu + 3
    static let shieldingOverlay = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
    static let lockScreenPanel = shieldingOverlay
    static let lockScreenNotch = NSWindow.Level(rawValue: shieldingOverlay.rawValue + 1)
}

enum OverlayPanelFactory {

    static func makePanel(frame: NSRect) -> FloatingPanel {
        let panel = FloatingPanel(
            contentRect: frame,
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        configure(panel)

        return panel
    }

    private static func configure(_ panel: FloatingPanel) {
        panel.isReleasedWhenClosed = false

        panel.isFloatingPanel = true

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false

        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false

        panel.animationBehavior = .none

        panel.level = OverlayWindowLevel.interactiveNotch
//        panel.level = OverlayWindowLevel.lockScreenNotch

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        panel.acceptsMouseMovedEvents = true
    }
}
