//
//  PanelController.swift
//  Notch
//
//  Created by Usanin Ivan on 10.08.2026.
//


import SwiftUI
import AppKit

@MainActor
final class PanelController {

    private let panelState: PanelState
    private let bluetoothNotificationViewModel: BluetoothNotificationViewModel
    
    private var hideTask: Task<Void, Never>?
    private var bluetoothEventObserver: NSObjectProtocol?
    
    init(
        panelState: PanelState,
        bluetoothNotificationViewModel: BluetoothNotificationViewModel
    ) {
        self.panelState = panelState
        self.bluetoothNotificationViewModel = bluetoothNotificationViewModel
    }

    func startBluetoothNotifications(from service: BluetoothDeviceServiceProtocol) {
        guard bluetoothEventObserver == nil else { return }

        bluetoothEventObserver = NotificationCenter.default.addObserver(
            forName: .bluetoothDeviceEvent,
            object: service,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[BluetoothDeviceNotificationKey.event]
                    as? BluetoothDeviceEvent else {
                return
            }

            Task { @MainActor [weak self] in
                self?.showBluetoothNotification(event)
            }
        }
    }

    func stopBluetoothNotifications() {
        if let bluetoothEventObserver {
            NotificationCenter.default.removeObserver(bluetoothEventObserver)
            self.bluetoothEventObserver = nil
        }
    }

    func showBluetoothNotification(
        _ event: BluetoothDeviceEvent,
        duration: TimeInterval = 3
    ) {
        switch event.kind {
        case .connected, .disconnected:
            break
        case .batteryLevelChanged:
            guard shouldShowBatteryAlert(for: event) else { return }
        case .becameAvailable, .becameUnavailable:
            return
        }

        bluetoothNotificationViewModel.update(with: event)
        showNotification(notification: .bluetooth, duration: duration)
    }

    private func shouldShowBatteryAlert(for event: BluetoothDeviceEvent) -> Bool {
        guard let batteryLevel = event.device.batteryLevel else { return false }

        let previousBatteryLevel = event.previousDevice?.batteryLevel
        let becameLow = batteryLevel <= 10
            && (previousBatteryLevel.map { $0 > 10 } ?? true)
        let becameFullyCharged = batteryLevel == 100 && previousBatteryLevel != 100

        return becameLow || becameFullyCharged
    }
    
    func setPanelMode(_ mode: PanelMode) {
        panelState.panelMode = mode
    }
    
    func getPanelMode() -> PanelMode {
        panelState.panelMode
    }
    
    func showCollapsedPreset() {
        withAnimation (.smooth(duration: 0.5)) {
            setPanelMode(.collapsed)
        }
    }
    
    func showExpandedPreset(_ preset: ExpandedPreset) {
        withAnimation (.smooth(duration: 0.5)) {
            setPanelMode(.expanded)
            panelState.expandedPreset = preset
        }
        hideNotification()
    }
    
    func showNotification(notification: NotificationPreset, duration: TimeInterval = 3) {
        withAnimation (.smooth(duration: 0.5)){
            hideTask?.cancel()
            panelState.notification = notification
            panelState.isNotificationTime = true
            
            hideTask = Task {
                try? await Task.sleep(for: .seconds(duration))
                
                guard !Task.isCancelled else {
                    return
                }
                
                panelState.isNotificationTime = false
            }
        }
        
    }
    
    func hideNotification() {
        hideTask?.cancel()
        hideTask = nil

        panelState.isNotificationTime = false
    }
    
    func triggerMacHaptic() {

        let performer = NSHapticFeedbackManager.defaultPerformer

        performer.perform(.levelChange, performanceTime: .now)
//        performer.perform(.levelChange, performanceTime: .now)
    }

    deinit {
        if let bluetoothEventObserver {
            NotificationCenter.default.removeObserver(bluetoothEventObserver)
        }
    }
}
