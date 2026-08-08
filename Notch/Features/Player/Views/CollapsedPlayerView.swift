//
//  CollapsedPlayerView.swift
//  UITests
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI


struct CollapsedPlayerView: View {
    
    @Environment(\.uiScale) private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        
        HStack (alignment: .center, spacing: 0) {

            ZStack {
                RoundedRectangle (cornerRadius: ui(8))
                    .fill(Color.white.opacity(0.2))
                    .frame(width: ui(26), height: ui(26))
            }
            
            
            ZStack {
            }
            .frame(width: ui(184), height: ui(33))
            .padding(.horizontal, ui(4))
//            .background(.red.opacity(0.2))
            
            
            ZStack {
                RoundedRectangle (cornerRadius: ui(8))
                    .fill(Color.white.opacity(0.2))
                    .frame(width: ui(26), height: ui(26))
            }

            
        }
        .padding(.horizontal, ui(4))
    }
}


#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)

        
        CollapsedPlayerView()
            .background(Color.blue.opacity(0.2))

    }
    .frame(width: 244, height: 33)
    .frame(width: 400, height: 100, alignment: .top)
}
