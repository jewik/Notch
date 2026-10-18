//
//  AppDelegate.swift

import os
import AppKit
import SwiftUI
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let overlaySpace = PanelOverlaySpace()
    private var overlayPanel: FloatingPanel?
    
    private var screenConfigurationObserver: NSObjectProtocol?
    
    private let panelSize = NSSize(
        width: 1200,
        height: 300
    )
    
    
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        
        NSApp.setActivationPolicy(.accessory)
        
        MediaKeysGatekeeperService.shared.start()
        BluetoothDeviceService.shared.start()
        
        AppContainer.shared.bluetoothNotificationsService.startBluetoothNotifications(
            from: BluetoothDeviceService.shared
        )
        
        startScreenObservers()
        showOverlayPanel()
        
        Log.general.info("Application did finished launching.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        
        MediaKeysGatekeeperService.shared.stop()
        AppContainer.shared.bluetoothNotificationsService.stopBluetoothNotifications()

        BluetoothDeviceService.shared.stop()
        
        overlayPanel?.orderOut(nil)
        overlaySpace?.close()
        
        Log.general.info("Application will terminate.")
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
        
        overlaySpace?.add(panel)
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
            .environment(AppContainer.shared)
        
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
