//
//  PanelController.swift
//  UITests
//
//  Created by Usanin Ivan on 04.08.2026.
//


import Observation
import SwiftUI

@Observable
@MainActor
final class PanelController {

    var preset : PanelPresets = .collapsed

    func setPreset(_ preset: PanelPresets) {
        withAnimation {
            self.preset = preset
        }
    }
    
    func getPreset() -> PanelPresets {
        preset
    }
    
    func expand() {
        if preset == .collapsed {
            setPreset(.home)
        }
    }
    
    func collapse() {
        if preset != .collapsed {
            setPreset(.collapsed)
        }
    }
    
    func toggle() {
        if preset == .collapsed {
            expand()
        } else {
            collapse()
        }
    }
}
