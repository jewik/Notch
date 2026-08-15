//
//  CollapsedPanelView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI


struct CollapsedContentView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale: CGFloat
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    
    var body: some View {
        VStack(spacing: ui(4)) {
            
            ZStack(alignment: .top) {
                
//                            CollapsedPlayerView()
                
                ZStack {
                    PanelShape(uiScale: scale)
                        .fill(.black)
                }
                .frame(width: ui(184), height: ui(32), alignment: .top)
                .onTapGesture {tap in
                    print("tapped")
                    container.panelController.showExpandedPreset(.home)
                }
            }
            
            if container.panelState.isNotificationTime {
                notificationView
                    .animation(.smooth(duration: 0.5), value: container.panelState.isNotificationTime)
            }
        }
    }
    
    @ViewBuilder
    private var notificationView: some View {
        
        switch container.panelState.notification {
            case .greeting:
            GreetingNotificationView().transition(.changePresetTransition)

            case .valediction:
            ValedictionNotificationView().transition(.changePresetTransition)
            
        }
    }
}


#Preview {
    CollapsedContentView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
        .environment(AppContainer())
}
