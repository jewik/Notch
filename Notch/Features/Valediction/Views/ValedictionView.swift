

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
                    NotchButton(
                        systemName: "",
                        title: "Cancel",
                        color: .indigo,
                        bgSize: CGSize(width: ui(100), height: ui(30)),
                        textSize: ui(16),
                        isActive: true,
                        action: {
                            container.panelController.showExpandedPreset(.home)
                        })

                    NotchButton(
                        systemName: "",
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
