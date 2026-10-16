import Observation

@Observable
final class BluetoothNotificationViewModel {
    private(set) var deviceName = "Bluetooth device"
    private(set) var message = ""
    private(set) var symbolName = "wave.3.right.circle.fill"

    func update(with event: BluetoothDeviceEvent) {
        deviceName = event.device.name
        symbolName = symbolName(for: event.device.category)

        switch event.kind {
        case .connected:
            if let batteryLevel = event.device.batteryLevel {
                message = "Connected · Battery \(batteryLevel)%"
            } else {
                message = "Connected"
            }

        case .disconnected:
            message = "Disconnected"

        case .batteryLevelChanged:
            if let batteryLevel = event.device.batteryLevel {
                if batteryLevel == 100 {
                    message = "Fully charged · 100%"
                } else {
                    message = "Low battery · \(batteryLevel)%"
                }
            } else {
                message = "Battery level unavailable"
            }

        case .becameAvailable:
            message = "Available nearby"

        case .becameUnavailable:
            message = "No longer available"
        }
    }

    private func symbolName(for category: BluetoothDeviceCategory) -> String {
        switch category {
        case .audio:
            return "headphones"
        case .keyboard:
            return "keyboard"
        case .pointingDevice:
            return "computermouse"
        case .keyboardAndPointingDevice, .peripheral:
            return "keyboard.badge.ellipsis"
        case .computer:
            return "laptopcomputer"
        case .phone:
            return "iphone"
        case .network:
            return "network"
        case .imaging:
            return "camera"
        case .wearable:
            return "applewatch"
        case .toy, .health, .unknown:
            return "wave.3.right.circle.fill"
        }
    }
}
