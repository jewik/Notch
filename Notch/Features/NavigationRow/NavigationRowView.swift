
//
//  Untitled.swift
//  UITests
//
//  Created by Usanin Ivan on 24.07.2026.
//



import SwiftUI

struct NavigationRowView: View {
    

    var body: some View {
        HStack (alignment: .center, spacing: 8) {
            DotButton(
                color: .red,
                action: {
                    AppContainer.shared.controller.showCollapsedPreset()
                    AppContainer.shared.controller.showNotification(notification: .valediction, duration: 5)
                }
            ) {
                Circle()
                    .fill(.black.opacity(0.6))
                    .frame(width: 5, height: 5)
            }
            
//            DotButton(
//                color: .indigo,
//                action: {}
//            ) {
//                Image(systemName: "gearshape.fill")
//                    .font(.system(size: 10, weight: .semibold))
//                    .foregroundStyle(.black.opacity(0.6))
//            }

            
            NotchButton(
                systemName: "house.fill",
                title: "Home",
                color: .white,
                bgSize: CGSize(width: 70, height: 26),
                textSize: 14,
                isActive: AppContainer.shared.panelState.expandedPreset == .home,
                action: {
                    AppContainer.shared.controller.showExpandedPreset(.home)
                })
            
//            Spacer()
            
                    }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
    }
}


struct DotButton<InnerContent: View>: View {
    
    let color: Color?
    let action: () -> Void
    
    @ViewBuilder
    let innerContent: () -> InnerContent
        
    @State private var isHovered = false
    
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color ?? .white)
                innerContent()
            }
            .frame(width: 14, height: 14)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }

    }
}
