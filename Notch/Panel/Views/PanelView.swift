

import SwiftUI
import UniformTypeIdentifiers
import os

struct PanelView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    
    @State private var contentSize: CGSize = .zero
    @State private var resizeAnimation: Animation = .smoothCollapceAnimation
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
            resizeAnimation = .bouncy(duration: 0.5)
        } else {
            resizeAnimation = .smooth(duration: 0.5)
        }
    }
    
    init() {
        contentSize = CGSize(width: 184, height: 30)
    }
    
    var body: some View {
        
        ZStack (alignment: .top){
            ZStack (alignment: .top) {
                
                Color.clear
                    .glassEffect(.clear, in: UnionPanelShape())
                    .environment(\.appearsActive, true)
                    .materialActiveAppearance(.active)
                    .animation(resizeAnimation, value: panelShadowColor)
                
                GeometryReader { geometry in
                    let totalHeight = geometry.size.height

                    let blackStop = totalHeight <= 30 ? 1.0 : 30.0 / totalHeight
                    UnionPanelShape()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black, location: blackStop),
                                    .init(color: .black.opacity(0.2), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: panelShadowColor, radius: 20)
                        .shadow(color: panelShadowColor, radius: 20)
                        .animation(resizeAnimation, value: panelShadowColor)
                }
                
            }
            .frame(
                width: contentSize.width + min(30, contentSize.height / 4) * 2,
                height: contentSize.height, alignment: .top
            )
            .animation(resizeAnimation, value: contentSize)
            
            
            
            
            ZStack(alignment: .top) {
                
                if AppContainer.shared.panelState.panelMode == .collapsed {
                    CollapsedContentView().transition(.collapseExpandTransition)
                } else if AppContainer.shared.panelState.panelMode == .expanded {
                    ExpandedContentView().transition(.collapseExpandTransition)
                } else {
                    Text("pashalka")
                }
                
                
            }
            .padding([.leading, .trailing, .bottom], extraContentPadding)
            
            .onGeometryChange(for: CGSize.self) { geo in
                geo.size
            } action: { size in
                Log.general.info("PanelView resize to: \(String(describing: size))")
                selectAnimation(to: size)
                contentSize = size
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
                print("onDrop")
                return true
            }
            .onChange(of: isDragging) {oldValue, newValue in
                if newValue {
                    AppContainer.shared.controller.showNotification(notification: .airdrop)
                }
            }
            
            
        }
        .frame(width: 1200, height: 300, alignment: .top)
        //        .background(.red)
        
    }
}

#Preview {
    PanelView()
        .background(.gray.opacity(0.1))
        .environment(AppContainer())
}

