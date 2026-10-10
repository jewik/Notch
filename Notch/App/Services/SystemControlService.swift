import Cocoa
import CoreAudio
import IOKit.graphics

class SystemControlService {
    static let shared = SystemControlService()
    
    private var isInternalVolumeChange = false
    private var defaultAudioDeviceID: AudioObjectID = 0
    private var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    
    private init() {
        setupAudioListener()
    }
    
    // MARK: - CoreAudio Volume Configuration
    private func setupAudioListener() {
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultAddress, 0, nil, &size, &defaultAudioDeviceID)
        
        if status == noErr {
            let callback: AudioObjectPropertyListenerProc = { (inObjectID, inNumberAddresses, inAddresses, inClientData) -> OSStatus in
                guard let clientData = inClientData else { return noErr }
                let service = Unmanaged<SystemControlService>.fromOpaque(clientData).takeUnretainedValue()
                
                guard !service.isInternalVolumeChange else { return noErr }
                
                if let currentVol = service.getCurrentVolume() {
                    service.notifyVolumeChanged(value: currentVol, source: "External (Headphones/System)")
                }
                return noErr
            }
            
            AudioObjectAddPropertyListener(defaultAudioDeviceID, &audioPropertyAddress, callback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        }
    }
    
    // MARK: - Public API for EventTap / UI
    func adjustVolume(by step: Float) {
        guard let currentVol = getCurrentVolume() else { return }
        let newVol = max(0.0, min(1.0, currentVol + step))
        
        isInternalVolumeChange = true
        setSystemVolume(to: newVol)
        notifyVolumeChanged(value: newVol, source: "Keyboard (Internal)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isInternalVolumeChange = false
        }
    }
    
    func toggleMute() {
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var isMuted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(defaultAudioDeviceID, &muteAddress, 0, nil, &size, &isMuted)
        isMuted = (isMuted == 0) ? 1 : 0
        AudioObjectSetPropertyData(defaultAudioDeviceID, &muteAddress, 0, nil, size, &isMuted)
        
        print("[Service] Mute toggled to: \(isMuted == 1)")
    }
    
    func adjustBrightness(by step: Float) {
        guard let currentBright = getCurrentBrightness() else { return }
        let newBright = max(0.0, min(1.0, currentBright + step))
        setSystemBrightness(to: newBright)
        notifyBrightnessChanged(value: newBright)
    }
    
    // MARK: - Low-Level Getters & Setters
    private func getCurrentVolume() -> Float? {
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = audioPropertyAddress
        
        let status = AudioObjectGetPropertyData(defaultAudioDeviceID, &address, 0, nil, &size, &volume)
        return (status == noErr) ? volume : nil
    }
    
    private func setSystemVolume(to value: Float) {
        var volume = Float32(value)
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = audioPropertyAddress
        
        AudioObjectSetPropertyData(defaultAudioDeviceID, &address, 0, nil, size, &volume)
    }
    
    private func getCurrentBrightness() -> Float? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if result == kIOReturnSuccess {
            let display: io_object_t = IOIteratorNext(iterator)
            if display != 0 {
                var brightness: Float = 0.0
                IODisplayGetFloatParameter(display, 0, kIODisplayBrightnessKey as CFString, &brightness)
                IOObjectRelease(display)
                IOObjectRelease(iterator)
                return brightness
            }
        }
        return nil
    }
    
    private func setSystemBrightness(to value: Float) {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if result == kIOReturnSuccess {
            let display: io_object_t = IOIteratorNext(iterator)
            if display != 0 {
                IODisplaySetFloatParameter(display, 0, kIODisplayBrightnessKey as CFString, value)
                IOObjectRelease(display)
                IOObjectRelease(iterator)
            }
        }
    }
    
    // MARK: - Output Dispatchers
    private func notifyVolumeChanged(value: Float, source: String) {
        print("[Service] Volume changed to \(Int(value * 100))% via \(source)")
        // Здесь вы будете вызывать метод отрисовки вашего кастомного HUD
        // NotificationCenter.default.post(name: .volumeChanged, object: nil, userInfo: ["value": value])
    }
    
    private func notifyBrightnessChanged(value: Float) {
        print("[Service] Brightness changed to \(Int(value * 100))%")
        // NotificationCenter.default.post(name: .brightnessChanged, object: nil, userInfo: ["value": value])
    }
}
