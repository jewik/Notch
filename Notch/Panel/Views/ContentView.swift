import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @Environment(PanelController.self)
    private var panelController
    
    @State private var isDragging: Bool = false
    
        var body: some View {
        
        ZStack (alignment: .top){
            content
            
            TogglePresetButton(action: {
                panelController.toggle()
                print("Toggle button pressed")
            })
        }
        .onContinuousHover{ phase in
            if phase == .ended {
                print("hoverEnded")
                panelController.collapse()
            }
        }
        .onDrop(
            of: [UTType.fileURL],
            isTargeted: $isDragging
        ) {
            providers in
            print("onDrop")
            return true
        }
        .onChange(of: isDragging) {oldValue, newValue in
            if newValue {
                panelController.setPreset(.tray)
            }
        }
        
    }
    
    @ViewBuilder
    private var content: some View {
        switch panelController.getPreset() {
        case .collapsed:
            CollapsedStateView()
//                .id("collapsed")
                .transition(.topCollapseExpand)
            
        case .home:
            HomeUI()
//                .id("home")
                .transition(.topCollapseExpand)
            
        case .tray:
            TrayUI()
//                .id("tray")
                .transition(.topCollapseExpand)
        }
    }

}

struct TogglePresetButton: View {

    let action: () -> Void
    
    @Environment(\.uiScale)
    private var scale: CGFloat
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    var body: some View {
        Button(action: action) {
            
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: ui(10))
                    .fill(Color.black.opacity(0.01))
                    .frame(width: ui(184), height: ui(33))
                
                Text("Mr. Notch")
                    .font(.system(size: ui(14), weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
