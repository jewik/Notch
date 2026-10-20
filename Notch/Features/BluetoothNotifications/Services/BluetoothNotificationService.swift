//
//  BluetoothNotificationService.swift
//  Notch
//
//  Created by Usanin Ivan on 18.10.2026.
//

import Observation
import AppKit
import os


@Observable
final class BluetoothNotificationService {
    
    
    private let bluetoothNotificationViewModel = BluetoothNotificationViewModel()
    private var bluetoothEventObserver: NSObjectProtocol?

    init(){}
    
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
        Log.service.info("BluetoothNotificationService start observing")
    }

    func stopBluetoothNotifications() {
        if let bluetoothEventObserver {
            NotificationCenter.default.removeObserver(bluetoothEventObserver)
            self.bluetoothEventObserver = nil
        }
        Log.service.info("BluetoothNotificationService stop observing")
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
        
//        showNotification(notification: .bluetooth, duration: duration)
        PanelNotificationsService.shared.post(
            BluetoothNotificationView(
                systemName: bluetoothNotificationViewModel.symbolName,
                deviceName: bluetoothNotificationViewModel.deviceName,
                message: bluetoothNotificationViewModel.message
            )
        )
    }

    private func shouldShowBatteryAlert(for event: BluetoothDeviceEvent) -> Bool {
        guard let batteryLevel = event.device.batteryLevel else { return false }

        let previousBatteryLevel = event.previousDevice?.batteryLevel
        let becameLow = batteryLevel <= 10
            && (previousBatteryLevel.map { $0 > 10 } ?? true)
        let becameFullyCharged = batteryLevel == 100 && previousBatteryLevel != 100

        return becameLow || becameFullyCharged
    }
}
