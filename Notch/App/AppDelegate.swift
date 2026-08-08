//
//  AppDelegate.swift
//  UITests
//
//  Created by Codex on 02.07.2026.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    @Environment(\.uiScale) var scale
    
    let container = AppContainer()
    
    private var overlayPanel: FloatingNotificationPanel?
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon and regular menu-bar presence. The app still runs
        // and can display AppKit windows/panels.
        NSApp.setActivationPolicy(.accessory)

        showOverlayPanel()
    }

    private func showOverlayPanel() {
//        let screen = NSScreen.main ?? NSScreen.screens.first
//        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
//        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }
        let screenFrame = screen.frame

        let panelSize = NSSize(
            width: 1200,
            height: 300
        )

        let panelFrame = NSRect(
            x: screenFrame.midX - panelSize.width / 2,
            y: screenFrame.maxY - panelSize.height + 1,
            width: panelSize.width,
            height: panelSize.height
        )

        let panel = FloatingNotificationPanel(contentRect: panelFrame)
        panel.contentView = makeHostingView()

        overlayPanel = panel

        // orderFrontRegardless makes the panel appear immediately, even though
        // this accessory-style app does not become the active foreground app.
        panel.orderFrontRegardless()
    }

    private func makeHostingView() -> NSView {
        let root = PanelView().environment(container.panelController)
        let hostingView = NSHostingView(rootView: root)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        return hostingView
    }
}

final class FloatingNotificationPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isFloatingPanel = true
        
        level = NSWindow.Level.mainMenu + 1
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
