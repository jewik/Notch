//
//  CollapsedPanelView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI
import os


struct CollapsedContentView: View {
    
    @State private var contentSize: CGSize = .zero
    
    private var notificationService = PanelNotificationsService.shared
    
    
    var body: some View {
        VStack(spacing: 4) {
            
            ZStack(alignment: .top) {
                
                ZStack {
                    PanelShape()
                        .fill(.black)
                }
                .frame(width: 184, height: 30, alignment: .top)
                .onTapGesture {tap in
                    AppContainer.shared.controller.showExpandedPreset(.home)
                }
            }
            
            if let current = notificationService.currentNotification {
                current.makeView()
                    .transition(.collapseExpandTransition)
            }
        }
    }
}


#Preview {
    CollapsedContentView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
//        .environment(AppContainer())
}
