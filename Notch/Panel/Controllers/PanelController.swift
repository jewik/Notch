//
//  PanelController.swift
//  Notch
//
//  Created by Usanin Ivan on 10.08.2026.
//


import SwiftUI
import AppKit

@MainActor
final class PanelController {
    
    private let panelState: PanelState
    
    
    private var hideTask: Task<Void, Never>?
    
    
    init(
        panelState: PanelState
    ) {
        self.panelState = panelState
        
    }
    private func setPanelMode(_ mode: PanelMode) {
        panelState.panelMode = mode
    }
    
    func getPanelMode() -> PanelMode {
        panelState.panelMode
    }
    
    func showCollapsedPreset() {
        withAnimation (.smooth) {
            setPanelMode(.collapsed)
        }
    }
    
    func showExpandedPreset(_ preset: ExpandedPreset) {
        if ScreenUnlockObserveService.shared.isLocked { return }
        
        withAnimation (.smooth) {
            setPanelMode(.expanded)
            panelState.expandedPreset = preset
        }
    }

    
    func triggerMacHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

}
