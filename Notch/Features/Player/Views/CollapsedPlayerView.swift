//
//  CollapsedPlayerView.swift
//  UITests
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI


struct CollapsedPlayerView: View {
    
    @Environment(\.uiScale) private var scale
    
    @State private var isCoverHovered: Bool = false
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        VStack (alignment: .center, spacing: 0) {
            
            
            HStack (alignment: .center, spacing: 0) {
                
                ZStack {
                    RoundedRectangle (cornerRadius: ui(8))
                        .fill(Color.white.opacity(0.2))
                        .frame(width: ui(26), height: ui(26))
                }
                .onHover { isCoverHovered = $0 }
                
                
                ZStack {
                }
                .frame(width: ui(184), height: ui(32))
                .padding(.horizontal, ui(4))
                //            .background(.red.opacity(0.2))
                
                
                ZStack {
                    RoundedRectangle (cornerRadius: ui(8))
                        .fill(Color.white.opacity(0.2))
                        .frame(width: ui(26), height: ui(26))
                }
                
                
            }
            .padding(.horizontal, ui(4))
            
            if isCoverHovered {
                ZStack (alignment: .center) {
                    Text("Here is track name")
                        .font(.system(size: ui(14), weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .frame(width: ui(184), height: ui(32))
                .transition(.collapseExpandTransition)
            }
        }
        .animation(.smooth(duration: 0.5), value: isCoverHovered)
    }
}


#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)

        
        CollapsedPlayerView()
            .background(Color.blue.opacity(0.2))

    }
    .frame(width: 244, height: 64)
    .frame(width: 400, height: 200, alignment: .top)
}
