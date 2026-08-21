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
    
    init(panelState: PanelState){
        self.panelState = panelState
    }
    
    func setPanelMode(_ mode: PanelMode) {
        panelState.panelMode = mode
    }
    
    func getPanelMode() -> PanelMode {
        panelState.panelMode
    }
    
    func showCollapsedPreset() {
        withAnimation (.smooth(duration: 0.5)) {
            setPanelMode(.collapsed)
        }
    }
    
    func showExpandedPreset(_ preset: ExpandedPreset) {
        withAnimation (.smooth(duration: 0.5)) {
            setPanelMode(.expanded)
            panelState.expandedPreset = preset
        }
        hideNotification()
    }
    
    func showNotification(notification: NotificationPreset, duration: TimeInterval = 3) {
        withAnimation (.smooth(duration: 0.5)){
            hideTask?.cancel()
            panelState.notification = notification
            panelState.isNotificationTime = true
            
            hideTask = Task {
                try? await Task.sleep(for: .seconds(duration))
                
                guard !Task.isCancelled else {
                    return
                }
                
                panelState.isNotificationTime = false
            }
        }
        
    }
    
    func hideNotification() {
        hideTask?.cancel()
        hideTask = nil

        panelState.isNotificationTime = false
    }
    
    func triggerMacHaptic() {

        let performer = NSHapticFeedbackManager.defaultPerformer

        performer.perform(.levelChange, performanceTime: .now)
//        performer.perform(.levelChange, performanceTime: .now)
    }
}
