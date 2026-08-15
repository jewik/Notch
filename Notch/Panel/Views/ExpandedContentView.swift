import SwiftUI
import UniformTypeIdentifiers

struct ExpandedContentView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    @State private var isDragging: Bool = false
    @State private var navRowWidth: CGFloat = 500
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        VStack {
            
            ZStack {
                NavigationRowView()
            }
            .frame(width: navRowWidth, height: ui(30))

            
            ZStack (alignment: .top){
                content
            }
            // Ключевой фикс: фиксируем идеальный размер по горизонтали,
            // чтобы контент не сжимался до нуля во время анимации parent ZStack
            .fixedSize(horizontal: true, vertical: false)
            .onGeometryChange(for: CGSize.self) { geo in
                geo.size
            } action: { size in
                // Анимируем изменение ширины плавно
                withAnimation(.smooth(duration: 0.5)) {
                    print("expandedpreset size", size)
                    navRowWidth = size.width
                }
            }
        }
        .onContinuousHover{ phase in
            if phase == .ended {
                print("hoverEnded")

                container.panelController.showCollapsedPreset()
            }
        }
        .animation(.smooth(duration: 0.5), value: navRowWidth)
        
    }
    
    @ViewBuilder
    private var content: some View {
        switch  container.panelState.expandedPreset {
        case .home:
            HomeUI()
                .transition(.collapseExpandTransition)
        case .tray:
            TrayUI()
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
