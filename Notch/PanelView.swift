import SwiftUI

struct PanelView: View {
    let fullWidth: CGFloat

    var body: some View {
        EdgeMergingPanelShape(fullWidth: fullWidth)
            .fill(.black)
            .ignoresSafeArea()
    }
}

/// Контур строится управляющими векторами Bézier. Радиус внешних углов растёт
/// вместе с раскрытием, а глубина вливания в край экрана остаётся постоянной.
private struct EdgeMergingPanelShape: Shape {
    let fullWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let openingProgress = fullWidth > 0 ? min(max(rect.width / fullWidth, 0), 1) : 0
        let mergeDepth = min(PanelGeometry.edgeMergeDepth, rect.height / 4)
        let cornerDepth = min(PanelGeometry.cornerRadius * openingProgress, rect.height / 4)
        let naturalWidth = mergeDepth + cornerDepth
        let horizontalScale = naturalWidth > 0 ? min(1, rect.width / naturalWidth) : 0
        let mergeWidth = mergeDepth * horizontalScale
        let cornerWidth = cornerDepth * horizontalScale
        let bezier = CGFloat(0.552_284_75)

        if horizontalScale < 1 {
            return narrowPath(in: rect, curveHeight: naturalWidth)
        }

        let edgeX = rect.maxX
        let shoulderX = edgeX - mergeWidth
        let bodyTop = rect.minY + mergeDepth
        let bodyBottom = rect.maxY - mergeDepth

        var path = Path()

        // Вогнутый переход от физического края экрана к верхней грани.
        path.move(to: CGPoint(x: edgeX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: shoulderX, y: bodyTop),
            control1: CGPoint(x: edgeX, y: rect.minY + mergeDepth * bezier),
            control2: CGPoint(x: shoulderX + mergeWidth * bezier, y: bodyTop)
        )

        // Выпуклый левый угол полностью раскрытой панели.
        path.addLine(to: CGPoint(x: rect.minX + cornerWidth, y: bodyTop))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: bodyTop + cornerDepth),
            control1: CGPoint(x: rect.minX + cornerWidth * (1 - bezier), y: bodyTop),
            control2: CGPoint(x: rect.minX, y: bodyTop + cornerDepth * (1 - bezier))
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bodyBottom - cornerDepth))
        path.addCurve(
            to: CGPoint(x: rect.minX + cornerWidth, y: bodyBottom),
            control1: CGPoint(x: rect.minX, y: bodyBottom - cornerDepth * (1 - bezier)),
            control2: CGPoint(x: rect.minX + cornerWidth * (1 - bezier), y: bodyBottom)
        )

        // Нижний переход зеркален верхнему.
        path.addLine(to: CGPoint(x: shoulderX, y: bodyBottom))
        path.addCurve(
            to: CGPoint(x: edgeX, y: rect.maxY),
            control1: CGPoint(x: shoulderX + mergeWidth * bezier, y: bodyBottom),
            control2: CGPoint(x: edgeX, y: rect.maxY - mergeDepth * bezier)
        )
        path.closeSubpath()

        return path
    }

    /// Один кубический сегмент вместо двух сжатых дуг. У него нет внутреннего
    /// стыка, поэтому профиль остаётся гладким вплоть до нулевой ширины.
    private func narrowPath(in rect: CGRect, curveHeight: CGFloat) -> Path {
        let edgeX = rect.maxX
        let controlOffset = curveHeight / 3

        var path = Path()
        path.move(to: CGPoint(x: edgeX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + curveHeight),
            control1: CGPoint(x: edgeX, y: rect.minY + controlOffset),
            control2: CGPoint(x: rect.minX, y: rect.minY + curveHeight - controlOffset)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - curveHeight))
        path.addCurve(
            to: CGPoint(x: edgeX, y: rect.maxY),
            control1: CGPoint(x: rect.minX, y: rect.maxY - curveHeight + controlOffset),
            control2: CGPoint(x: edgeX, y: rect.maxY - controlOffset)
        )
        path.closeSubpath()
        return path
    }
}
