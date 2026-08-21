

import SwiftUI

struct ValedictionNotificationView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    
    var body: some View {
        
        ZStack (alignment: .center) {
                
                
                HStack (alignment: .center, spacing: ui(10)) {
                    ValedictionButton(
                        title: "Cancel",
                        color: .indigo,
                        bgSize: CGSize(width: ui(100), height: ui(30)),
                        textSize: ui(16),
                        isActive: true,
                        action: {
                            container.panelController.showExpandedPreset(.home)
                        })

                    ValedictionButton(
                        title: "Terminate",
                        color: .red,
                        bgSize: CGSize(width: ui(100), height: ui(30)),
                        textSize: ui(16),
                        isActive: true,
                        action: {
                            Task {
                                container.panelController.hideNotification()
                                try? await Task.sleep(for: .seconds(1))
                                NSApplication.shared.terminate(nil)
                            }
                        })
                }
            
        }
        .frame(width: ui(230), height: ui(40), alignment: .top)
        .onAppear {
            print("valediction called")
        }
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


#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)

        
        ValedictionNotificationView()
//            .background(Color.blue.opacity(0.2))
            .environment(AppContainer())

    }
    .frame(width: 230, height: 40)
    .frame(width: 400, height: 300, alignment: .top)
}
