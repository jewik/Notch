//
//  AudioDeviceType.swift
//  Notch
//
//  Created by Usanin Ivan on 20.08.2026.
//

import Foundation

enum AudioDeviceType {
    case builtin
    case bluetooth
    case airplay
    case lineOut // Plugged-in
    case usb
    case unknown
    
    var iconName: String {
        switch self {
        case .builtin: return "laptopcomputer"
        case .bluetooth: return "beats.headphones" // или "bluetooth"
        case .airplay: return "airplayaudio"
        case .lineOut: return "cable.connector"
        case .usb: return "usb.generic"
        case .unknown: return "speaker.wave.2"
        }
    }
}

struct AudioDevice: Identifiable, Equatable {
    let id: UInt32 // AudioObjectID из CoreAudio
    let name: String
    let uid: String
    let type: AudioDeviceType
    
    var isVirtualDevice: Bool {
        let lowercasedName = name.lowercased()
        let lowercasedUid = uid.lowercased()
        
        return lowercasedName.contains("teams") ||
               lowercasedName.contains("zoom") ||
               lowercasedName.contains("loopback") ||
               lowercasedName.contains("soundflower") ||
               lowercasedUid.contains("mstarget")    }
}
