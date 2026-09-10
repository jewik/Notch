
//
//  Untitled.swift
//  UITests
//
//  Created by Usanin Ivan on 24.07.2026.
//



import SwiftUI

struct NavigationRowView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    
    var body: some View {
        HStack (alignment: .center, spacing: 2) {
            BackButton(
                action: {
                    container.panelController.showCollapsedPreset()
                    container.panelController.showNotification(notification: .valediction, duration: 5)
                }
            )
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: 10,
                        bottom: 0,
                        trailing: 4
                    )
                )
            
            NotchButton(
                systemName: "house.fill",
                title: "Home",
                color: .white,
                bgSize: CGSize(width: 70, height: 26),
                textSize: 14,
                isActive: container.panelState.expandedPreset == .home,
                action: {
                    container.panelController.showExpandedPreset(.home)
                })
            
            Spacer()
            
            NotchButton(
                systemName: "gearshape.fill",
                title: "",
                color: .white,
                bgSize: CGSize(width: 26, height: 26),
                textSize: 14,
                isActive: false,
                action: {})
            .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
    }
}


struct BackButton: View {
    
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(Color.red)

                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 5, height: 5)
                    }
                    .frame(width: 14, height: 14)
                }
        .buttonStyle(.plain)

    }
}
