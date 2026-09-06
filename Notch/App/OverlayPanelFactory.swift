
//  OverlayPanelFactory.swift
//

import AppKit
//import SwiftUI

enum OverlayPanelFactory {

    static func makePanel(frame: NSRect) -> FloatingNotificationPanel {
        let panel = FloatingNotificationPanel(
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

    private static func configure(_ panel: FloatingNotificationPanel) {
        panel.isReleasedWhenClosed = false

        panel.isFloatingPanel = true

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false

        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false

        panel.animationBehavior = .none

        panel.level = .mainMenu + 1

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        panel.acceptsMouseMovedEvents = true
    }
}
