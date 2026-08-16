
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
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        HStack (alignment: .center, spacing: ui(2)) {
            BackButton(
                action: {
                    container.panelController.showCollapsedPreset()
                    container.panelController.showNotification(notification: .valediction, duration: 5)
                }
            )
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: ui(10),
                        bottom: 0,
                        trailing: ui(4)
                    )
                )
            
            NotchButton(
                systemName: "house.fill",
                title: "Home",
                color: .white,
                bgSize: CGSize(width: ui(74), height: ui(26)),
                textSize: ui(14),
                isActive: container.panelState.expandedPreset == .home,
                action: {
                    container.panelController.showExpandedPreset(.home)
                })
            

            NotchButton(
                systemName: "tray.fill",
                title: "Tray",
                color: .white,
                bgSize: CGSize(width: ui(68), height: ui(26)),
                textSize: ui(14),
                isActive: container.panelState.expandedPreset == .tray,
                action: {
                    container.panelController.showExpandedPreset(.tray)
                })            
            Spacer()
            
            NotchButton(
                systemName: "gearshape.fill",
                title: "",
                color: .white,
                bgSize: CGSize(width: ui(26), height: ui(26)),
                textSize: ui(14),
                isActive: false,
                action: {})
            .padding(.trailing, ui(10))
        }
        .frame(maxWidth: .infinity)
        .frame(height: ui(32))
    }
}


struct BackButton: View {
    
    let action: () -> Void
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var body: some View {
        Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(Color.red)

                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: ui(5), height: ui(5))
                    }
                    .frame(width: ui(14), height: ui(14))
                }
        .buttonStyle(.plain)

    }
}
