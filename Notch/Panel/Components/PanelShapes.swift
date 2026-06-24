import SwiftUI

/// Superellipse-профиль даёт непрерывный G2-переход нижних углов к прямым граням.
/// Верхняя грань остаётся прямой и вплотную примыкает к краю экрана.
struct EdgeMergingPanelShape: Shape {
    let pointMultiplier: CGFloat

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(
            expansion: rect.height,
            pointMultiplier: pointMultiplier
        )
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

struct PanelEarShape: Shape {
    let side: PanelEarSide
    let pointMultiplier: CGFloat

    /// Дискретизирует аналитическую superellipse-кривую. У её концов нулевая
    /// кривизна, поэтому профиль мягко вливается в прямые участки без дугового шва.
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(
            expansion: rect.height,
            pointMultiplier: pointMultiplier
        )
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
    static let minimumRoundingRadius: CGFloat = 10
    static let maximumRoundingRadius: CGFloat = 24

    private static let minimumRoundingHeight: CGFloat = PanelSizePreset.hidden.height
    private static let maximumRoundingHeight: CGFloat = PanelSizePreset.home.height
    private static let minimumExponent: CGFloat = 2.2
    private static let maximumExponent: CGFloat = 3.3

    let radius: CGFloat
    let exponent: CGFloat

    init(expansion: CGFloat, pointMultiplier: CGFloat = 1) {
        let progress = Self.progress(for: expansion, pointMultiplier: pointMultiplier)
        radius = Self.lerp(
            from: Self.minimumRoundingRadius * pointMultiplier,
            to: Self.maximumRoundingRadius * pointMultiplier,
            progress: progress
        )
        exponent = Self.lerp(
            from: Self.minimumExponent,
            to: Self.maximumExponent,
            progress: progress
        )
    }

    private static func progress(for expansion: CGFloat, pointMultiplier: CGFloat) -> CGFloat {
        let minimumHeight = minimumRoundingHeight * pointMultiplier
        let maximumHeight = maximumRoundingHeight * pointMultiplier
        let range = maximumHeight - minimumHeight
        guard range > 0 else { return 1 }

        return min(max((expansion - minimumHeight) / range, 0), 1)
    }

    private static func lerp(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + (end - start) * progress
    }
}
