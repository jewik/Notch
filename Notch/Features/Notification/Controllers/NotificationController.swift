//
//  NotificationController.swift
//  Notch
//
//  Created by Usanin Ivan on 10.08.2026.
//

import Foundation



final class NotificationController {
    
    let panelState: PanelState
    
    private var hideTask: Task<Void, Never>?
    
    init(panelState: PanelState){
        self.panelState = panelState
    }
    
    func showNotification(notification: NotificationPreset, duration: TimeInterval = 3) {
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
    
    func hideNotification() {
        hideTask?.cancel()
        hideTask = nil

        panelState.isNotificationTime = false
    }
    
    //...
}
