//
//  HUDService.swift
//  Notch
//
//  Created by Usanin Ivan on 11.10.2026.
//

import AppKit
import ApplicationServices
import AudioToolbox
import Combine
import CoreAudio
import Foundation



@MainActor
final class HUDService {
    
    static let shared = HUDService()
    
    func update(hudKey: InterceptedMediaKey){
        
        if let value = executeHardwareAdjustment(for:hudKey, step: 0.0625) {
            DispatchQueue.main.async {
                self.executeUIAdjustment(for: hudKey, step: value)
            }
        }
        
    }
    
    private func executeUIAdjustment(for hudKey: InterceptedMediaKey, step: Float) {
        switch hudKey {
        case .volumeUp, .volumeDown, .volumeMute:
            AppContainer.shared.HUDViewmodel.kind = .volume
            
        case.brightnessDown, .brightnessUp:
            AppContainer.shared.HUDViewmodel.kind = .brightness
        }
        
        AppContainer.shared.HUDViewmodel.value = step
        
        AppContainer.shared.controller.showNotification(notification: .HUD, duration: 1.5)

    }
    
    
    private func executeHardwareAdjustment(for hudKey: InterceptedMediaKey, step: Float) -> Float? {
        
        
        let calculatedValue: Float?
        
        switch hudKey {
        case .volumeUp, .volumeDown:
            let direction: Float = hudKey == .volumeUp ? 1 : -1
            if let result = SystemVolumeControl.adjust(by: direction * step) {
                calculatedValue = result.muted ? 0 : result.value
            } else { calculatedValue = nil }
            
        case .volumeMute:
            if let result = SystemVolumeControl.toggleMute() {
                calculatedValue = result.muted ? 0 : result.value
            } else { calculatedValue = nil }
            
            
        case.brightnessDown, .brightnessUp:
            let direction: Float = hudKey == .brightnessUp ? 1 : -1
            if let value = DisplayBrightnessControl.adjust(by: direction * step) {
                calculatedValue = value
            } else { calculatedValue = nil }
        }
        
        return calculatedValue
    }
}

private enum SystemVolumeControl {
    struct Reading {
        let value: Float
        let muted: Bool
    }
    
    private static let volumeSelectors: [AudioObjectPropertySelector] = [
        kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        kAudioDevicePropertyVolumeScalar,
    ]
    
    static func adjust(by delta: Float) -> Reading? {
        guard let device = defaultOutputDevice(),
              let current = volume(of: device) else { return nil }
        
        let next = min(max((muted(device) == true ? 0 : current) + delta, 0), 1)
        guard setVolume(next, for: device) else { return nil }
        
        let shouldMute = next == 0
        if hasMuteControl(device), !setMuted(shouldMute, for: device) { return nil }
        return Reading(value: next, muted: shouldMute)
    }
    
    static func toggleMute() -> Reading? {
        guard let device = defaultOutputDevice(),
              let value = volume(of: device),
              let currentMute = muted(device),
              setMuted(!currentMute, for: device) else { return nil }
        return Reading(value: value, muted: !currentMute)
    }
    
    private static func defaultOutputDevice() -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                         0, nil, &size, &device) == noErr,
              device != kAudioObjectUnknown else { return nil }
        return device
    }
    
    private static func volume(of device: AudioObjectID) -> Float? {
        for selector in volumeSelectors {
            if let value = readFloat(device, selector: selector) { return value }
        }
        return nil
    }
    
    private static func setVolume(_ value: Float, for device: AudioObjectID) -> Bool {
        for selector in volumeSelectors where writeFloat(value, to: device, selector: selector) {
            return true
        }
        return false
    }
    
    private static func muted(_ device: AudioObjectID) -> Bool? {
        guard let value = readUInt32(device, selector: kAudioDevicePropertyMute) else { return nil }
        return value != 0
    }
    
    private static func setMuted(_ muted: Bool, for device: AudioObjectID) -> Bool {
        writeUInt32(muted ? 1 : 0, to: device, selector: kAudioDevicePropertyMute)
    }
    
    private static func hasMuteControl(_ device: AudioObjectID) -> Bool {
        var address = address(kAudioDevicePropertyMute)
        return AudioObjectHasProperty(device, &address)
    }
    
    private static func readFloat(_ device: AudioObjectID,
                                  selector: AudioObjectPropertySelector) -> Float? {
        var property = address(selector)
        guard AudioObjectHasProperty(device, &property) else { return nil }
        var value: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        guard AudioObjectGetPropertyData(device, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }
    
    private static func readUInt32(_ device: AudioObjectID,
                                   selector: AudioObjectPropertySelector) -> UInt32? {
        var property = address(selector)
        guard AudioObjectHasProperty(device, &property) else { return nil }
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }
    
    private static func writeFloat(_ value: Float, to device: AudioObjectID,
                                   selector: AudioObjectPropertySelector) -> Bool {
        var property = address(selector)
        guard propertyIsSettable(device, property: &property) else { return false }
        var value = value
        return AudioObjectSetPropertyData(device, &property, 0, nil,
                                          UInt32(MemoryLayout<Float>.size), &value) == noErr
    }
    
    private static func writeUInt32(_ value: UInt32, to device: AudioObjectID,
                                    selector: AudioObjectPropertySelector) -> Bool {
        var property = address(selector)
        guard propertyIsSettable(device, property: &property) else { return false }
        var value = value
        return AudioObjectSetPropertyData(device, &property, 0, nil,
                                          UInt32(MemoryLayout<UInt32>.size), &value) == noErr
    }
    
    private static func propertyIsSettable(_ device: AudioObjectID,
                                           property: inout AudioObjectPropertyAddress) -> Bool {
        guard AudioObjectHasProperty(device, &property) else { return false }
        var settable = DarwinBoolean(false)
        guard AudioObjectIsPropertySettable(device, &property, &settable) == noErr,
              settable.boolValue else { return false }
        return true
    }
    
    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}

private enum DisplayBrightnessControl {
    private typealias GetBrightness = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightness = @convention(c) (UInt32, Float) -> Int32
    
    private static let framework = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_LAZY
    )
    private static let getBrightness: GetBrightness? = symbol("DisplayServicesGetBrightness")
    private static let setBrightness: SetBrightness? = symbol("DisplayServicesSetBrightness")
    
    static func adjust(by delta: Float) -> Float? {
        guard let display = controllableDisplay(), let getBrightness, let setBrightness else { return nil }
        var current: Float = 0
        guard getBrightness(display, &current) == 0, current.isFinite else { return nil }
        let next = min(max(current + delta, 0), 1)
        guard setBrightness(display, next) == 0 else { return nil }
        return next
    }
    
    private static func controllableDisplay() -> CGDirectDisplayID? {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return nil }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displays, &count) == .success else { return nil }
        
        let active = Array(displays.prefix(Int(count)))
        let candidates = [CGMainDisplayID()] + active.filter { $0 != CGMainDisplayID() }
        guard let getBrightness else { return nil }
        return candidates.first { display in
            var level: Float = 0
            return getBrightness(display, &level) == 0 && level.isFinite
        }
    }
    
    private static func symbol<T>(_ name: String) -> T? {
        guard let framework, let pointer = dlsym(framework, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}
