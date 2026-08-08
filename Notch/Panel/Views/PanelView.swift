

import SwiftUI
import UniformTypeIdentifiers


struct PanelView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    @State private var contentSize: CGSize = .zero
    @State private var resizeAnimation: Animation = .smoothCollapceAnimation
    @State private var isPanelHovered: Bool = false
    @State private var isDragging: Bool = false
    
    let extraContentPadding: CGFloat = 0
    
    private var panelShadowRadius: CGFloat {
        isPanelHovered ? ui(20) : 0
    }

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    private func selectAnimation(to newSize: CGSize){
        if newSize.width >= self.contentSize.width && newSize.height >= self.contentSize.height {
            resizeAnimation = .bouncyExpandAnimation
        } else {
            resizeAnimation = .smoothCollapceAnimation
        }
    }

    var body: some View {
        
        ZStack (alignment: .top){
                ZStack (alignment: .top) {
                    
                    UnionPanelShape(
                        uiScale: 1
                    )
                    .fill(.black)
                    .shadow(color: .black, radius: panelShadowRadius)
                    .animation(resizeAnimation, value: panelShadowRadius)
                    
                }
                .frame(
                    width: contentSize.width + min(ui(30), contentSize.height / 4) * 2,
                    height: contentSize.height, alignment: .top
                )
                .animation(resizeAnimation, value: contentSize)



            
            ZStack(alignment: .top) {
                    if container.panelState.isExpanded {
                        ExpandedContentView()
                            .transition(.collapseExpandTransition)
                    } else {
                        CollapsedContentView()
                            .transition(.collapseExpandTransition)
                    }
            }
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: ui(extraContentPadding),
                        bottom: ui(extraContentPadding),
                        trailing: ui(extraContentPadding)
                    )
                )

                .onGeometryChange(for: CGSize.self) { geo in
                    geo.size
                } action: { size in
                    print(size)
                    selectAnimation(to: size)
                    contentSize = size
                }
                .onHover { isPanelHovered = $0}
            
            // hande airdrop
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
                        container.panelState.expand()
                        container.expandedContentController.setPreset(.tray)
                    }
                }
                

        }
        .frame(width: ui(1200), height: ui(300), alignment: .top)
            
    }
}

#Preview {
    PanelView()
        .background(.gray.opacity(0.1))
}

