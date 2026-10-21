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

    let uiScale: CGFloat
    
    private var notificationService = PanelNotificationsService.shared

    init(uiScale: CGFloat = 1) {
        self.uiScale = uiScale
    }
    
    
    var body: some View {
        VStack(alignment: .center) {
            
            //            ZStack(alignment: .top) {
            
            //                ZStack {
            PanelShape()
                .fill(.black)
//                .stroke(Color.blue, lineWidth: 6)
            //                }
                .frame(
                    width: 180 * uiScale * 1.017,
                    height: 30 * uiScale * 1.1,
                    alignment: .top
                )
                .onTapGesture {tap in
                    AppContainer.shared.controller.showExpandedPreset(.home)
                }
            //            }
            
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
