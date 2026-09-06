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
    
    
    @State private var contentSize: CGSize = .zero
    
    
    var body: some View {
        VStack(spacing: 4) {
            
            ZStack(alignment: .top) {
                
                //                            CollapsedPlayerView()
                
                ZStack {
                    PanelShape()
                        .fill(.black)
                }
                .frame(width: 184, height: 32, alignment: .top)
                .onTapGesture {tap in
                    print("tapped")
                    container.panelController.showExpandedPreset(.home)
                }
            }
            
            if container.panelState.isNotificationTime {
                notificationView
            }
        }
    }
    
    @ViewBuilder
    private var notificationView: some View {
        
        switch container.panelState.notification {
        case .greeting:
            GreetingNotificationView().transition(.collapseExpandTransition)
            
        case .valediction:
            ValedictionNotificationView().transition(.collapseExpandTransition)
            
        case .airdrop:
            AirDropNotificationView().transition(.collapseExpandTransition)
            
        }
    }
}


#Preview {
    CollapsedContentView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
        .environment(AppContainer())
}
