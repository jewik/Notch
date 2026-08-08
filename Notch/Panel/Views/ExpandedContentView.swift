import SwiftUI
import UniformTypeIdentifiers

struct ExpandedContentView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @State private var isDragging: Bool = false
    
        var body: some View {
        
        ZStack (alignment: .top){
            content
        }
        .onContinuousHover{ phase in
            if phase == .ended {
                print("hoverEnded")
                container.panelState.collapse()
                container.collapsedContentController.setPreset(.none)
            }
        }
        
    }
    
    @ViewBuilder
    private var content: some View {
        switch container.panelState.expandedPreset {
        case .home:
            HomeUI()
                .transition(.collapseExpandTransition)
        case .tray:
            TrayUI()
                .transition(.collapseExpandTransition)
        case .greeting:
            GreetingView()
                .transition(.collapseExpandTransition)
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
