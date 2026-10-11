//
//  HUDViewModel.swift
//  Notch
//
//  Created by Usanin Ivan on 11.10.2026.
//

import Observation


@Observable
final class HUDViewModel {
    
    enum Kind: Equatable {
        case brightness
        case volume

        var symbolName: String {
            switch self {
            case .brightness:
                return "sun.max.fill"
            case .volume:
                return "speaker.wave.2.fill"
            }
        }
    }

    var kind: Kind = .volume
    var value: Float = 0
}
