import SwiftUI
import UniformTypeIdentifiers

struct ExpandedContentView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    
    @State private var isDragging: Bool = false
    @State private var navRowWidth: CGFloat = 500
    
    var body: some View {
        VStack (spacing: 0) {
            
            ZStack {
                NavigationRowView()
            }
            .frame(width: navRowWidth, height: 30)
            
            
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.01))
                    .frame(width: 184, height: 33)
                
                Text("Mr. Notch")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
