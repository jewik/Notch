//
//  Home.swift
//  UITests
//
//  Created by Usanin Ivan on 17.07.2026.
//
import SwiftUI

struct HomeUI: View {
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            NavigationRowView()
            HStack(alignment: .top, spacing: 0) {
                
                PlayerView()
//                    .background(.red.opacity(0.1))
                Divider()
                    .padding(.vertical, ui(10))
                
                JLampView()
//                    .background(.blue.opacity(0.1))
            }
        }
        .frame(width: ui(600), height: ui(150 + 34), alignment: .top)
    }
    
}





#Preview {

        ZStack {
            PanelShape(uiScale: 1)
                .fill(.black)
            HomeUI()
//                .background(Color.cyan.opacity(0.1))
        }
    .frame(width: 600, height: 150 + 34, alignment: .top)

}
