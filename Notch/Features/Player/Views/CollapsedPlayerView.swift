//
//  CollapsedPlayerView.swift
//  UITests
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI


struct CollapsedPlayerView: View {
    
    @State private var isCoverHovered: Bool = false
    
    var body: some View {
        
        VStack (alignment: .center, spacing: 0) {
            
            
            HStack (alignment: .center, spacing: 0) {
                
                ZStack {
                    RoundedRectangle (cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 26, height: 26)
                }
                .onHover { isCoverHovered = $0 }
                
                
                ZStack {
                }
                .frame(width: 184, height: 32)
                .padding(.horizontal, 4)
                //            .background(.red.opacity(0.2))
                
                
                ZStack {
                    RoundedRectangle (cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 26, height: 26)
                }
                
                
            }
            .padding(.horizontal, 4)
            
            if isCoverHovered {
                ZStack (alignment: .center) {
                    Text("Here is track name")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .frame(width: 184, height: 32)
                .transition(.collapseExpandTransition)
            }
        }
        .animation(.smooth(duration: 0.5), value: isCoverHovered)
    }
}


#Preview {
    ZStack {
        PanelShape()
            .fill(.black)

        
        CollapsedPlayerView()
            .background(Color.blue.opacity(0.2))

    }
    .frame(width: 244, height: 64)
    .frame(width: 400, height: 200, alignment: .top)
}
