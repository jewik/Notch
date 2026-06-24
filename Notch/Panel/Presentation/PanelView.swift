import SwiftUI

struct PanelView: View {
    @ObservedObject var presentation: PanelPresentationModel
    @ObservedObject var contentMetrics: PanelContentMetrics
    let openRoute: (PanelRoute) -> Void

    var body: some View {
        PanelSurfaceView(pointMultiplier: contentMetrics.pointMultiplier) {
            if presentation.isContentVisible {
                switch presentation.route {
                case .home:
                    HomePageView(pointMultiplier: contentMetrics.pointMultiplier)
                case .sysMonitor:
                    SysMonitorPageView(
                        pointMultiplier: contentMetrics.pointMultiplier,
                        openRoute: openRoute
                    )
                case .clipboard:
                    ClipboardPageView(pointMultiplier: contentMetrics.pointMultiplier)
                }
            }
        }
    }
}
