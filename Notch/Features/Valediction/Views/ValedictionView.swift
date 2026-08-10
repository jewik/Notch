

import SwiftUI

struct ValedictionView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    
    var body: some View {
        
        ZStack (alignment: .center) {
                
                
                VStack (alignment: .center, spacing: ui(10)) {
                    ValedationButton(
                        title: "Cancel",
                        color: .indigo,
                        accessibilityLabel: "Cancel",
                        action: {
                            container.panelController.showExpandedPreset(.home)
                        }
                    )
                    
                    ValedationButton(
                        title: "Terminate",
                        color: .red,
                        accessibilityLabel: "Terminate",
                        action: {
                            Task {
                                container.notificationController.hideNotification()
                                try? await Task.sleep(for: .seconds(1))
                                NSApplication.shared.terminate(nil)
                            }
                        }
                    )
                }
                .padding(ui(20))
            
            
        }
        .frame(width: ui(220), height: ui(150), alignment: .bottom)
        .onAppear {
            print("valediction called")
        }
    }
}

struct ValedationButton : View{
    
    let title: String
    let color: Color
    let accessibilityLabel: String
    let action: () -> Void
    
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: ui(20))
                        .fill(color.opacity(0.2))
                        .frame(width: ui(180), height: ui(40))

                        Text(title)
                            .font(.system(size: ui(16), weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(color)
                }
            }
            .buttonStyle(.plain)
        
            .accessibilityLabel(accessibilityLabel)
            .help(accessibilityLabel)
        
    }
}


#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)

        
        ValedictionView()
//            .background(Color.blue.opacity(0.2))
            .environment(AppContainer())

    }
    .frame(width: 220, height: 150)
    .frame(width: 400, height: 300, alignment: .top)
}
