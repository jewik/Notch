//
//  AudioDeviceService.swift
//  Notch
//
//  Created by Usanin Ivan on 20.08.2026.
//

import Foundation
import CoreAudio

protocol AudioDeviceServiceProtocol: AnyObject {
    var onDevicesChanged: (([AudioDevice]) -> Void)? { get set }
    var onActiveDeviceChanged: ((UInt32) -> Void)? { get set }
    
    func fetchAvailableOutputDevices() -> [AudioDevice]
    func fetchActiveOutputDeviceID() -> UInt32
    func setAsDefaultOutputDevice(_ deviceID: UInt32)
    func startListening()
    func stopListening()
}

final class AudioDeviceService: AudioDeviceServiceProtocol {
    var onDevicesChanged: (([AudioDevice]) -> Void)?
    var onActiveDeviceChanged: ((UInt32) -> Void)?
    
    private var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain // Используем Main вместо Master для macOS 12+
    )
    
    private var defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    func fetchAvailableOutputDevices() -> [AudioDevice] {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Получаем размер массива устройств
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }
        
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: count)
        
        // Получаем сами ID устройств
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceIDs) == noErr else { return [] }
        
        let allDevices: [AudioDevice] = deviceIDs.compactMap { id in
            guard isOutputDevice(id) else { return nil }
            return convertToAudioDevice(id)
        }
        
        return allDevices.filter { !$0.isVirtualDevice }
    }
    
    func fetchActiveOutputDeviceID() -> UInt32 {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = defaultDeviceAddress
        
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    func setAsDefaultOutputDevice(_ deviceID: UInt32) {
        var id = deviceID
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = defaultDeviceAddress
        
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &id)
    }

    // Регистрация слушателей изменений системы
    func startListening() {
        let clientData = Unmanaged.passUnretained(self).toOpaque()
        
        // Слушаем появление/удаление устройств в системе
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, devicesChangedCallback, clientData)
        // Слушаем изменение дефолтного устройства пользователем извне
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, defaultDeviceChangedCallback, clientData)
    }
    
    func stopListening() {
        let clientData = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, devicesChangedCallback, clientData)
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, defaultDeviceChangedCallback, clientData)
    }
    
    // MARK: - CoreAudio Helpers
    
    private func isOutputDevice(_ id: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
        return status == noErr && size > 0
    }
    
    private func convertToAudioDevice(_ id: AudioObjectID) -> AudioDevice? {
        // Получаем имя
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var cfName: CFString = "" as CFString
        var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &cfName) == noErr else { return nil }
        
        // Получаем UID (для определения AirPlay/Bluetooth)
        var uidSize = UInt32(MemoryLayout<CFString>.size)
        var cfUid: CFString = "" as CFString
        var uidAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(id, &uidAddress, 0, nil, &uidSize, &cfUid) == noErr else { return nil }
        
        let name = cfName as String
        let uid = cfUid as String
        
        // Эвристика определения типов по UID (CoreAudio не отдает явный Enum типа устройства)
        let type: AudioDeviceType
        if uid.contains("AirPlay") {
            type = .airplay
        } else if uid.contains("Bluetooth") || uid.contains("BlueTooth") {
            type = .bluetooth
        } else if uid.contains("BuiltIn") {
            type = .builtin
        } else if uid.contains("USB") {
            type = .usb
        } else {
            type = .lineOut
        }
        
        return AudioDevice(id: id, name: name, uid: uid, type: type)
    }
}

// MARK: - C Callbacks
private let devicesChangedCallback: AudioObjectPropertyListenerProc = { _, _, _, inClientData in
    guard let UnsafeData = inClientData else { return noErr }
    let service = Unmanaged<AudioDeviceService>.fromOpaque(UnsafeData).takeUnretainedValue()
    
    let updatedDevices = service.fetchAvailableOutputDevices()
    DispatchQueue.main.async {
        service.onDevicesChanged?(updatedDevices)
    }
    return noErr
}

private let defaultDeviceChangedCallback: AudioObjectPropertyListenerProc = { _, _, _, inClientData in
    guard let UnsafeData = inClientData else { return noErr }
    let service = Unmanaged<AudioDeviceService>.fromOpaque(UnsafeData).takeUnretainedValue()
    
    let activeID = service.fetchActiveOutputDeviceID()
    DispatchQueue.main.async {
        service.onActiveDeviceChanged?(activeID)
    }
    return noErr
}
