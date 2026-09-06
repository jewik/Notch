//
//  AppDelegate.swift

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    let container = AppContainer()
    
    private var overlayPanel: FloatingNotificationPanel?
    
    private var screenConfigurationObserver: NSObjectProtocol?
    
    private let panelSize = NSSize(
        width: 1200,
        height: 300
    )
    
    
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        // The app has no Dock icon and does not behave
        // like a regular foreground application.
        NSApp.setActivationPolicy(.accessory)
        
        startScreenObservers()
        
        showOverlayPanel()
    }
    
    deinit {
        if let observer = screenConfigurationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Panel
    
    private func showOverlayPanel() {
        // Do not create the panel twice.
        if let panel = overlayPanel {
            panel.orderFrontRegardless()
            return
        }
        
        guard let screen = targetScreen() else {
            return
        }
        
        let panel = OverlayPanelFactory.makePanel(
            frame: frame(for: screen)
        )
        
        panel.contentView = makeHostingView()
        
        overlayPanel = panel
        
        panel.orderFrontRegardless()
    }
    
    private func updateOverlayPanelFrame() {
        guard let panel = overlayPanel else {
            return
        }
        
        guard let screen = targetScreen() else {
            return
        }
        
        let newFrame = frame(for: screen)
        
        panel.setFrame(
            newFrame,
            display: true,
            animate: false
        )
    }

    
    private func targetScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }
    
    private func frame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        
        return NSRect(
            x: screenFrame.midX - panelSize.width / 2,
            y: screenFrame.maxY - panelSize.height + 1,
            width: panelSize.width,
            height: panelSize.height
        )
    }
    
    private func startScreenObservers() {
        screenConfigurationObserver =
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            
            Task { @MainActor [weak self] in
                self?.updateOverlayPanelFrame()
            }
        }
    }
    
    private func makeHostingView() -> NSView {
        let rootView = PanelView()
            .environment(container)
        
        let hostingView = NSHostingView(
            rootView: rootView
        )
        
        hostingView.autoresizingMask = [
            .width,
            .height
        ]
        
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor =
        NSColor.clear.cgColor
        
        return hostingView
    }
}
