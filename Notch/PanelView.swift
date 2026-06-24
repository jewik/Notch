import Combine
import SwiftUI

final class PanelContentVisibility: ObservableObject {
    @Published var showsHomeContent = false
}

struct PanelView: View {
    @Environment(\.displayScale) private var displayScale
    @ObservedObject var contentVisibility: PanelContentVisibility
    @StateObject private var systemLoad = SystemLoadMonitor()

    var body: some View {
        ZStack(alignment: .top) {
            EdgeMergingPanelShape()
                .fill(.black)
                .ignoresSafeArea()

            if contentVisibility.showsHomeContent {
                HomePageView(
                    snapshot: systemLoad.snapshot,
                    scale: displayScale
                )
            }
        }
    }
}

private struct HomePageView: View {
    let snapshot: SystemLoadSnapshot
    let scale: CGFloat

    private var resolvedScale: CGFloat {
        max(scale, 1)
    }

    private var rowWidth: CGFloat {
        1000 / resolvedScale
    }

    private var serviceRowHeight: CGFloat {
        70 / resolvedScale
    }

    private var systemRowHeight: CGFloat {
        130 / resolvedScale
    }

    var body: some View {
        VStack(spacing: 0) {
            ServiceButtonRow()
                .frame(width: rowWidth, height: serviceRowHeight, alignment: .leading)

            SystemLoadRow(snapshot: snapshot, scale: resolvedScale)
                .frame(width: rowWidth, height: systemRowHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct ServiceButtonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.clear
        }
    }
}

private struct SystemLoadRow: View {
    let snapshot: SystemLoadSnapshot
    let scale: CGFloat

    private var horizontalPadding: CGFloat {
        22 / scale
    }

    private var gaugeSpacing: CGFloat {
        18 / scale
    }

    var body: some View {
        HStack(alignment: .center, spacing: gaugeSpacing) {
            SystemLoadGauge(
                title: "RAM",
                value: snapshot.memoryLoad,
                tint: .blue
            )

            SystemLoadGauge(
                title: "CPU",
                value: snapshot.cpuLoad,
                tint: .green
            )
        }
        .padding(.leading, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct SystemLoadGauge: View {
    let title: String
    let value: Double
    let tint: Color

    private var percentageText: String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        Gauge(value: value, in: 0...1) {
            Text(title)
        } currentValueLabel: {
            Text(percentageText)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .frame(width: 52, height: 52)
        .accessibilityLabel(title)
        .accessibilityValue(percentageText)
    }
}

enum PanelEarSide {
    case left
    case right
}

struct PanelEarView: View {
    let side: PanelEarSide

    var body: some View {
        PanelEarShape(side: side)
            .fill(.black)
            .ignoresSafeArea()
    }
}

/// Superellipse-профиль даёт непрерывный G2-переход нижних углов к прямым граням.
/// Верхняя грань остаётся прямой и вплотную примыкает к краю экрана.
private struct EdgeMergingPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(expansion: rect.height)
        let cornerDepth = min(profile.radius, rect.width / 2, rect.height)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerDepth))
        ContinuousCornerPath.add(
            to: &path,
            from: CGPoint(x: rect.minX, y: rect.maxY - cornerDepth),
            horizontal: cornerDepth,
            vertical: cornerDepth,
            exponent: profile.exponent,
            beginsVertically: true
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerDepth, y: rect.maxY))
        ContinuousCornerPath.add(
            to: &path,
            from: CGPoint(x: rect.maxX - cornerDepth, y: rect.maxY),
            horizontal: cornerDepth,
            vertical: -cornerDepth,
            exponent: profile.exponent,
            beginsVertically: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct PanelEarShape: Shape {
    let side: PanelEarSide

    /// Дискретизирует аналитическую superellipse-кривую. У её концов нулевая
    /// кривизна, поэтому профиль мягко вливается в прямые участки без дугового шва.
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(expansion: rect.height)
        var path = Path()

        switch side {
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            ContinuousCornerPath.add(
                to: &path,
                from: CGPoint(x: rect.maxX, y: rect.maxY),
                horizontal: -rect.width,
                vertical: -rect.height,
                exponent: profile.exponent,
                beginsVertically: true
            )
        case .right:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            ContinuousCornerPath.add(
                to: &path,
                from: CGPoint(x: rect.maxX, y: rect.minY),
                horizontal: -rect.width,
                vertical: rect.height,
                exponent: profile.exponent,
                beginsVertically: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        path.closeSubpath()
        return path
    }
}

private enum ContinuousCornerPath {
    /// Дискретизирует аналитическую superellipse-кривую. У её концов нулевая
    /// кривизна, поэтому профиль мягко вливается в прямые участки без дугового шва.
    static func add(
        to path: inout Path,
        from origin: CGPoint,
        horizontal: CGFloat,
        vertical: CGFloat,
        exponent: CGFloat,
        beginsVertically: Bool
    ) {
        let power = 2 / exponent
        let segmentCount = 32

        for index in 1...segmentCount {
            let angle = CGFloat(index) / CGFloat(segmentCount) * .pi / 2
            let fastAxis = pow(sin(angle), power)
            let slowAxis = 1 - pow(cos(angle), power)
            let x = beginsVertically ? slowAxis : fastAxis
            let y = beginsVertically ? fastAxis : slowAxis
            path.addLine(to: CGPoint(
                x: origin.x + horizontal * x,
                y: origin.y + vertical * y
            ))
        }
    }
}

struct ContinuousCornerProfile {
    /// Экспериментальная сила скругления: 1.0 — текущий профиль,
    /// меньше — ближе к обычному радиусу, больше — более выраженный continuous corner.
    private static let roundingForce: CGFloat = 0.1

    let radius: CGFloat
    let exponent: CGFloat

    init(expansion: CGFloat) {
        radius = min(max(expansion * 0.3, 0), 32)
        let widthDependentExponent = min(max(4.2 + expansion / 420, 4.2), 15)
        exponent = 2 + (widthDependentExponent - 2) * Self.roundingForce
    }
}
