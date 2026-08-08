//
//  PeekZoneUI.swift
//  UITests
//
//  Created by Usanin Ivan on 31.07.2026.
//



import SwiftUI


struct CollapsedStateView: View {
    
    @Environment(\.uiScale)
    private var scale: CGFloat
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
//            CollapsedPlayerView()
            
            ZStack(alignment: .top) {
            }
            .frame(width: ui(184), height: ui(33), alignment: .top)
            //        .background(.red)
        }

    }
}


#Preview {
    CollapsedStateView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
}
