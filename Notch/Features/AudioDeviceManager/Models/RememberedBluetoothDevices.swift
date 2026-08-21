//
//  RememberedBluetoothDevices.swift
//  Notch
//
//  Created by Usanin Ivan on 20.08.2026.
//

import Foundation

struct RememberedBluetoothDevice: Identifiable, Equatable {
    var id: String { macAddress } // Используем MAC-адрес как уникальный ID
    let name: String
    let macAddress: String
    let isConnected: Bool
    let rawDevice: AnyObject // Ссылка на оригинальный IOBluetoothDevice для вызова методов подключения

    // Ручная реализация протокола Equatable
    static func == (lhs: RememberedBluetoothDevice, rhs: RememberedBluetoothDevice) -> Bool {
        // Сравниваем только базовые типы, которые гарантированно Equatable
        return lhs.macAddress == rhs.macAddress &&
               lhs.name == rhs.name &&
               lhs.isConnected == rhs.isConnected
    }
}
