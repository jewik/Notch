import SwiftUI

enum PanelEarSide {
    case left
    case right
}

struct PanelEarView: View {
    let side: PanelEarSide
    @ObservedObject var contentMetrics: PanelContentMetrics

    var body: some View {
        PanelEarShape(
            side: side,
            pointMultiplier: contentMetrics.pointMultiplier
        )
            .fill(.black)
            .ignoresSafeArea()
    }
}
