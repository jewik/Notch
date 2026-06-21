import SwiftUI

struct PanelView: View {
    var body: some View {
        EdgeMergingPanelShape()
            .fill(.black)
            .ignoresSafeArea()
    }
}

/// Superellipse-профиль даёт непрерывный G2-переход к прямым граням. Одна
/// геометрия используется для выпуклых углов и вогнутых переходов у экрана.
private struct EdgeMergingPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let profile = ContinuousCornerProfile(width: rect.width)
        let mergeDepth = min(profile.radius, rect.width / 2)
        let cornerDepth = min(profile.radius, max(0, rect.width - mergeDepth))
        let edgeX = rect.maxX
        let shoulderX = edgeX - mergeDepth
        let bodyTop = rect.minY + mergeDepth
        let bodyBottom = rect.maxY - mergeDepth

        var path = Path()
        path.move(to: CGPoint(x: edgeX, y: rect.minY))

        addContinuousCorner(
            to: &path,
            from: CGPoint(x: edgeX, y: rect.minY),
            horizontal: -mergeDepth,
            vertical: mergeDepth,
            exponent: profile.exponent,
            beginsVertically: true
        )
        path.addLine(to: CGPoint(x: rect.minX + cornerDepth, y: bodyTop))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: rect.minX + cornerDepth, y: bodyTop),
            horizontal: -cornerDepth,
            vertical: cornerDepth,
            exponent: profile.exponent,
            beginsVertically: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bodyBottom - cornerDepth))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: rect.minX, y: bodyBottom - cornerDepth),
            horizontal: cornerDepth,
            vertical: cornerDepth,
            exponent: profile.exponent,
            beginsVertically: true
        )
        path.addLine(to: CGPoint(x: shoulderX, y: bodyBottom))
        addContinuousCorner(
            to: &path,
            from: CGPoint(x: shoulderX, y: bodyBottom),
            horizontal: mergeDepth,
            vertical: mergeDepth,
            exponent: profile.exponent,
            beginsVertically: false
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

    init(width: CGFloat) {
        radius = min(max(width * 0.075, 8), 32)
        let widthDependentExponent = min(max(4.2 + width / 420, 4.2), 15)
        exponent = 2 + (widthDependentExponent - 2) * Self.roundingForce
    }
}
