
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
        HStack (alignment: .center, spacing: 0) {
            BackButton(
                action: {
                    container.panelController.showCollapsedPreset()
                    container.notificationController.showNotification(notification: .valediction)
                }
            )
                .padding(.leading, ui(10))
            
            ServiceRowButtonUI(
                systemName: "house.fill",
                title: "Home",
                accessibilityLabel: "Home",
                isActive: container.panelState.expandedPreset == .home,
                action: {
                    container.panelController.showExpandedPreset(.home)
                })
            .padding(.leading, ui(8))
            

            ServiceRowButtonUI(
                systemName: "tray.fill",
                title: "Tray",
                accessibilityLabel: "Tray",
                isActive: container.panelState.expandedPreset == .tray,
                action: {
                    container.panelController.showExpandedPreset(.tray)
                })
            .padding(.leading, ui(4))
            
            Spacer()
            
            ServiceRowButtonUI(
                systemName: "gearshape.fill",
//                title: "",
                accessibilityLabel: "settings",
                isActive: false,
                action: {})
            .padding(.trailing, ui(4))
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

struct ServiceRowButtonUI: View {
    let systemName: String
    var title: String?
    let accessibilityLabel: String
    let isActive: Bool
    let action: () -> Void
    
    @Environment(\.uiScale)
    private var scale
    
    @State private var isHovered = false

    private func points(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var isHighlighted: Bool {
        isActive || isHovered
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: points(2)) {
                Image(systemName: systemName)
                    .font(.system(size: points(14), weight: .semibold))
//                    .background(Color.red.opacity(0.2))

                if let title {
                    Text(title)
                        .font(.system(size: points(14), weight: .semibold, design: .rounded))
                        .lineLimit(1)
//                        .background(Color.blue.opacity(0.2))
                }
            }            .padding(points(4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .white : .white.opacity(0.72))
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: points(12), style: .continuous)
                    .fill(.white.opacity(0.14))
            }
        }
        .onHover { isHovered = $0 }
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}
