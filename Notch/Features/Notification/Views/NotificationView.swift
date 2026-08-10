//
//  NotificationView.swift
//  Notch
//
//  Created by Usanin Ivan on 10.08.2026.
//



import SwiftUI


struct NotificationView: View {
    
    @Environment(AppContainer.self) private var container
    
    @Environment(\.uiScale) private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        if container.panelState.isNotificationTime {
            content
                .animation(.smooth(duration: 0.5), value: container.panelState.isNotificationTime)
        }
    }
    
    
    @ViewBuilder
    private var content: some View {
        
        switch container.panelState.notification {
            case .greeting:
            GreetingNotificationView().transition(.changePresetTransition)

            case .valediction:
            ValedictionView().transition(.changePresetTransition)
            
        }
    }
}
