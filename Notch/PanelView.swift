import SwiftUI

struct PanelView: View {
    var body: some View {
        EdgeMergingPanelShape()
            .fill(.black)
            .ignoresSafeArea()
    }
}

/// Superellipse-профиль даёт непрерывный G2-переход к прямым граням. Верхние
/// переходы мягко вливаются в край экрана, нижние образуют выпуклые G2-углы.
private struct EdgeMergingPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(expansion: rect.height)
        let mergeDepth = min(profile.radius, rect.height / 2)
        let cornerDepth = min(profile.radius, max(0, rect.height - mergeDepth))
        let bodyLeft = rect.minX + mergeDepth
        let bodyRight = rect.maxX - mergeDepth
        let shoulderY = rect.minY + mergeDepth

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        addContinuousCorner(
            to: &path,
            from: CGPoint(x: rect.minX, y: rect.minY),
            horizontal: mergeDepth,
            vertical: mergeDepth,
            exponent: profile.exponent,
            beginsVertically: false
        )
        path.addLine(to: CGPoint(x: bodyLeft, y: rect.maxY - cornerDepth))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: bodyLeft, y: rect.maxY - cornerDepth),
            horizontal: cornerDepth,
            vertical: cornerDepth,
            exponent: profile.exponent,
            beginsVertically: true
        )
        path.addLine(to: CGPoint(x: bodyRight - cornerDepth, y: rect.maxY))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: bodyRight - cornerDepth, y: rect.maxY),
            horizontal: cornerDepth,
            vertical: -cornerDepth,
            exponent: profile.exponent,
            beginsVertically: false
        )
        path.addLine(to: CGPoint(x: bodyRight, y: shoulderY))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: bodyRight, y: shoulderY),
            horizontal: mergeDepth,
            vertical: -mergeDepth,
            exponent: profile.exponent,
            beginsVertically: true
        )
        path.closeSubpath()
        return path
    }

    /// Дискретизирует аналитическую superellipse-кривую. У её концов нулевая
    /// кривизна, поэтому профиль мягко вливается в прямые участки без дугового шва.
    private func addContinuousCorner(
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

private struct ContinuousCornerProfile {
    /// Экспериментальная сила скругления: 1.0 — текущий профиль,
    /// меньше — ближе к обычному радиусу, больше — более выраженный continuous corner.
    private static let roundingForce: CGFloat = 0.3

    let radius: CGFloat
    let exponent: CGFloat

    init(expansion: CGFloat) {
        radius = min(max(expansion * 0.075, 8), 32)
        let widthDependentExponent = min(max(4.2 + expansion / 420, 4.2), 15)
        exponent = 2 + (widthDependentExponent - 2) * Self.roundingForce
    }
}
