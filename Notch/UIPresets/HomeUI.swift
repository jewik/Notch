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
        HStack(alignment: .center, spacing: 0) {
            
            AudioSwitcherView()
//                                .background(.red.opacity(0.1))
            Divider()
                .padding(.vertical, ui(10))

            
            FastFolderView()
            //                    .background(.blue.opacity(0.1))
        }
        .frame(height: ui(150))
//        .background(.red)
    }
    
}





#Preview {

        ZStack {
            PanelShape(uiScale: 1)
                .fill(.black)
            HStack(alignment: .center, spacing: 0) {
                
                AudioSwitcherView()
                                    .background(.red.opacity(0.1))
                Divider()
                    .padding(.vertical, 10)

                
                FastFolderView()
                                    .background(.blue.opacity(0.1))
            }
            .frame(height: 150)

        }
//    .frame(width: 600, height: 150, alignment: .top)
    .environment(AppContainer())

}
