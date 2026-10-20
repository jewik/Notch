

import SwiftUI
import os

struct ValedictionNotificationView: PanelNotification {
    
    let id = UUID()
    let priority = 10 // Высокий приоритет
    let duration: TimeInterval = 5.0
    
    func makeView() -> AnyView {
        AnyView(ValedictionView())
    }
}

struct ValedictionView: View {
    var body: some View {
        ZStack (alignment: .center) {
            
            
            HStack (alignment: .center, spacing: 10) {
                ValedictionButton(
                    title: "Cancel",
                    color: .indigo,
                    bgSize: CGSize(width: 100, height: 30),
                    textSize: 16,
                    isActive: true,
                    action: {
                        AppContainer.shared.controller.showExpandedPreset(.home)
                        PanelNotificationsService.shared.hideCurrent()
                    })
                
                ValedictionButton(
                    title: "Terminate",
                    color: .red,
                    bgSize: CGSize(width: 100, height: 30),
                    textSize: 16,
                    isActive: true,
                    action: { NSApplication.shared.terminate(nil) })
            }
            
        }
        .frame(width: 230, height: 40, alignment: .top)
    }
}


struct ValedictionButton: View {
    var title: String
    let color: Color
    let bgSize: CGSize
    let textSize: CGFloat
    let isActive: Bool
    var disabled: Bool?
    let action: () -> Void
    
    
    @State private var isHovered = false
    
    private var isHighlighted: Bool {
        isActive || isHovered
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                
                
                Text(title)
                    .font(.system(size: textSize, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(color)
                
                
                RoundedRectangle(cornerRadius: bgSize.width / 2, style: .continuous)
                    .fill(isHighlighted ? color.opacity(0.14) : .clear)
                    .frame(width: bgSize.width, height: bgSize.height)
            }
            .frame(width: bgSize.width, height: bgSize.height, alignment: .leading)
            .clipShape(
                RoundedRectangle(cornerRadius: bgSize.width / 2, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? color : color.opacity(0.72))
        
        .onHover { hovering in
            withAnimation (.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .disabled(disabled ?? false)
    }
}

