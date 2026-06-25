import SwiftUI

struct PanelView: View {
    @ObservedObject var presentation: PanelPresentationModel
    @ObservedObject var contentMetrics: PanelContentMetrics
    let openRoute: (PanelRoute) -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * contentMetrics.pointMultiplier
    }

    private var serviceRowHeight: CGFloat {
        points(35)
    }

    private var elementAnimation: Animation {
        .easeInOut(duration: 0.18)
    }

    var body: some View {
        PanelSurfaceView(pointMultiplier: contentMetrics.pointMultiplier) {
            GeometryReader { proxy in
                if presentation.isChromeVisible {
                    let panelWidth = proxy.size.width
                    let contentHeight = max(proxy.size.height - serviceRowHeight, 0)

                    VStack(spacing: 0) {
                        PanelServiceRow(
                            pointMultiplier: contentMetrics.pointMultiplier,
                            activeRoute: presentation.route,
                            openRoute: openRoute
                        )
                        .frame(width: panelWidth, height: serviceRowHeight, alignment: .leading)

                        if presentation.isContentVisible {
                            contentView
                                .frame(width: panelWidth, height: contentHeight, alignment: .top)
                                .id(presentation.route)
                                .transition(.panelElementBlur)
                        }
                    }
                    .frame(width: panelWidth, height: proxy.size.height, alignment: .top)
                    .transition(.panelElementBlur)
                }
            }
            .animation(elementAnimation, value: presentation.isChromeVisible)
            .animation(elementAnimation, value: presentation.isContentVisible)
            .animation(elementAnimation, value: presentation.route)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch presentation.route {
        case .home:
            HomePageView(pointMultiplier: contentMetrics.pointMultiplier)
        case .sysMonitor:
            SysMonitorPageView(pointMultiplier: contentMetrics.pointMultiplier)
        case .clipboard:
            ClipboardPageView(pointMultiplier: contentMetrics.pointMultiplier)
        }
    }
}

private extension AnyTransition {
    static var panelElementBlur: AnyTransition {
        .modifier(
            active: PanelElementBlurModifier(opacity: 0, blurRadius: 10),
            identity: PanelElementBlurModifier(opacity: 1, blurRadius: 0)
        )
    }
}

private struct PanelElementBlurModifier: ViewModifier {
    let opacity: Double
    let blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blurRadius)
    }
}

private struct PanelServiceRow: View {
    let pointMultiplier: CGFloat
    let activeRoute: PanelRoute
    let openRoute: (PanelRoute) -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        HStack(spacing: 0) {
            ServiceRouteButton(
                systemName: "house",
                accessibilityLabel: "Home",
                isActive: activeRoute == .home,
                pointMultiplier: pointMultiplier
            ) {
                openRoute(.home)
            }
            
            ServiceRouteButton(
                systemName: "doc.on.clipboard",
                accessibilityLabel: "Clipboard",
                isActive: activeRoute == .clipboard,
                pointMultiplier: pointMultiplier
            ) {
                openRoute(.clipboard)
            }

            Spacer(minLength: 0)

            ServiceRouteButton(
                systemName: "waveform.path.ecg",
                accessibilityLabel: "System Monitor",
                isActive: activeRoute == .sysMonitor,
                pointMultiplier: pointMultiplier
            ) {
                openRoute(.sysMonitor)
            }


        }
    }
}

private struct ServiceRouteButton: View {
    let systemName: String
    let accessibilityLabel: String
    let isActive: Bool
    let pointMultiplier: CGFloat
    let action: () -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: points(15), weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .white : .white.opacity(0.72))
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: points(6), style: .continuous)
                    .fill(.white.opacity(0.14))
                    .padding(points(4))
            }
        }
        .frame(width: points(35))
        .frame(maxHeight: .infinity)
        .accessibilityLabel(accessibilityLabel)
    }
}
