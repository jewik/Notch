

import SwiftUI
import UniformTypeIdentifiers
import os

struct PanelView: View {
    
    @State private var contentSize: CGSize = .zero
    @State private var resizeAnimation: Animation = .smooth
    @State private var isPanelHovered: Bool = false
    @State private var isDragging: Bool = false
    
    let extraContentPadding: CGFloat = 0
    
    private var panelShadowColor: Color {
        isPanelHovered || AppContainer.shared.panelState.isNotificationTime ? .black.opacity(0.8) : .clear
    }
    private var panelStrokeColor: Color {
        AppContainer.shared.panelState.panelMode == .expanded || AppContainer.shared.panelState.isNotificationTime ? .white.opacity(0.08) : .clear
    }
    
    private func selectAnimation(to newSize: CGSize){
        if newSize.width >= self.contentSize.width && newSize.height >= self.contentSize.height {
            resizeAnimation = .bouncy
        } else {
            resizeAnimation = .smooth
        }
    }
    
    init() {
        contentSize = CGSize(width: 184, height: 30)
    }
    
    var body: some View {
        
        ZStack (alignment: .top){

            surface

            content
            .padding([.leading, .trailing, .bottom], extraContentPadding)
            
            .onGeometryChange(for: CGSize.self) { geo in
                geo.size
            } action: { size in
                Log.ui.info("PanelView resize to: \(String(describing: size))")
                selectAnimation(to: size)
                withAnimation(resizeAnimation) {
                    contentSize = size
                }
            }
            .onHover {
                isPanelHovered = $0
                if isPanelHovered {
                    AppContainer.shared.controller.triggerMacHaptic()
                }
            }
            
            // hande airdrop
            .onDrop(
                of: [UTType.fileURL],
                isTargeted: $isDragging
            ) {
                providers in
                Log.ui.info("File dragged to panel")
                return true
            }
            .onChange(of: isDragging) {oldValue, newValue in
                if newValue {
                    PanelNotificationsService.shared.post(AirDropNotificationView())
                }
            }
            
            
        }
        .frame(width: 1200, height: 300, alignment: .top)
        //        .background(.red)
        
    }
    
    @ViewBuilder
    private var surface : some View {
        ZStack (alignment: .top) {
            
            Color.clear
                .glassEffect(.clear, in: UnionPanelShape())
                .environment(\.appearsActive, true)
                .materialActiveAppearance(.active)
                .shadow(color: panelShadowColor, radius: 20)
                .animation(.smooth, value: panelShadowColor)


            AnimatedPanelBackground(height: contentSize.height)
                            
        }
        .frame(
            width: contentSize.width + min(30, contentSize.height / 4) * 2,
            height: contentSize.height, alignment: .top
        )
    }
    
    @ViewBuilder
    private var content : some View {
        ZStack(alignment: .top) {
            
            if AppContainer.shared.panelState.panelMode == .collapsed {
                CollapsedContentView().transition(.collapseExpandTransition)
            } else if AppContainer.shared.panelState.panelMode == .expanded {
                ExpandedContentView().transition(.collapseExpandTransition)
            } else {
                Text("pashalka")
            }
        }
    }
}


struct AnimatedPanelBackground: View, Animatable {
    
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }
    
    var body: some View {
        let blackStop = min(1, 30 / max(height, 1))
        
        UnionPanelShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: blackStop),
                        .init(color: .black.opacity(0.2), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

    }
}


#Preview {
    PanelView()
        .background(.gray.opacity(0.1))
        .environment(AppContainer())
}

