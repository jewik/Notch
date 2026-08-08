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
        
        ZStack(alignment: .top) {
            
//            CollapsedPlayerView()
            
            ZStack {
                PanelShape(uiScale: scale)
                    .fill(.indigo)
            }
            .frame(width: ui(184), height: ui(33), alignment: .top)
            .onTapGesture {tap in
                print("tapped")
                container.panelState.expand()
                container.expandedContentController.setPreset(.home)
            }
        }
    }
}


#Preview {
    CollapsedContentView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
        .environment(AppContainer())
}
