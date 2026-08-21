//
//  BluetoothDeviceService.swift
//  Notch
//
//  Created by Usanin Ivan on 20.08.2026.
//

import Foundation
import IOBluetooth

protocol BluetoothDeviceServiceProtocol: AnyObject {
    var onBluetoothDevicesChanged: (([RememberedBluetoothDevice]) -> Void)? { get set }
    func fetchRememberedAudioDevices() -> [RememberedBluetoothDevice]
    func connectDevice(_ device: RememberedBluetoothDevice, completion: @escaping (Bool) -> Void)
}

final class BluetoothDeviceService: NSObject, BluetoothDeviceServiceProtocol {
    var onBluetoothDevicesChanged: (([RememberedBluetoothDevice]) -> Void)?
    
    override init() {
        super.init()
        registerForNotifications()
    }
    
    func fetchRememberedAudioDevices() -> [RememberedBluetoothDevice] {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return []
        }
        
        return pairedDevices.compactMap { device in
            // Отфильтровываем только аудио-устройства (наушники, колонки, гарнитуры)
            let deviceClass = device.deviceClassMajor
            // 0x04 — это Major Class для Audio/Video устройств в спецификации Bluetooth
            guard deviceClass == 0x04 else { return nil }
            
            return RememberedBluetoothDevice(
                name: device.name ?? "Неизвестное устройство",
                macAddress: device.addressString ?? "",
                isConnected: device.isConnected(),
                rawDevice: device
            )
        }
    }
    
    func connectDevice(_ device: RememberedBluetoothDevice, completion: @escaping (Bool) -> Void) {
        guard let bluetoothDevice = device.rawDevice as? IOBluetoothDevice else {
            completion(false)
            return }
        
        if bluetoothDevice.isConnected() {
            completion(true)
            return
        }
        
        // Асинхронное подключение, чтобы не блокировать UI-поток
        DispatchQueue.global(qos: .userInitiated).async {
            let status = bluetoothDevice.openConnection()
            
            DispatchQueue.main.async {
                if status == kIOReturnSuccess {
                    completion(true)
                } else {
                    print("Ошибка подключения Bluetooth: \(status)")
                    completion(false)
                }
            }
        }
    }
    
    private func registerForNotifications() {
        // Подписываемся на системные уведомления о подключении/отключении Bluetooth-устройств
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(bluetoothStateChanged))
    }
    
    @objc private func bluetoothStateChanged() {
        let updated = fetchRememberedAudioDevices()
        DispatchQueue.main.async {
            self.onBluetoothDevicesChanged?(updated)
        }
    }
}
