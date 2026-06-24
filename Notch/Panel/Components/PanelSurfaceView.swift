import SwiftUI

struct PanelSurfaceView<Content: View>: View {
    let pointMultiplier: CGFloat
    private let content: Content

    init(pointMultiplier: CGFloat, @ViewBuilder content: () -> Content) {
        self.pointMultiplier = pointMultiplier
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            EdgeMergingPanelShape(pointMultiplier: pointMultiplier)
                .fill(.black)
                .ignoresSafeArea()

            content
        }
    }
}
