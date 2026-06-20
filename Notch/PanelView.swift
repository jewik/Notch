import SwiftUI

struct PanelView: View {
    var body: some View {
        EdgeMergingPanelShape()
            .fill(.black)
            .ignoresSafeArea()
    }
}

/// Силуэт панели без правых углов: верхняя и нижняя грани заканчиваются
/// негативными окружностями точно на физическом краю экрана.
private struct EdgeMergingPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let mergeDepth = min(PanelGeometry.edgeMergeDepth, rect.width / 2, rect.height / 4)
        let edgeX = rect.maxX
        let shoulderX = edgeX - mergeDepth
        let corner = min(PanelGeometry.cornerRadius, shoulderX - rect.minX, rect.height / 4)
        let bodyTop = rect.minY + mergeDepth
        let bodyBottom = rect.maxY - mergeDepth
        let circleControl = mergeDepth * 0.552_284_75

        var path = Path()

        // Четверть окружности вырезает верхний угол из чёрной формы.
        path.move(to: CGPoint(x: edgeX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: shoulderX, y: bodyTop),
            control1: CGPoint(x: edgeX, y: rect.minY + circleControl),
            control2: CGPoint(x: shoulderX + circleControl, y: bodyTop)
        )

        // Верхняя и левая стороны сохраняют мягкое скругление панели.
        path.addLine(to: CGPoint(x: rect.minX + corner, y: bodyTop))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: bodyTop + corner),
            control1: CGPoint(x: rect.minX + corner * 0.45, y: bodyTop),
            control2: CGPoint(x: rect.minX, y: bodyTop + corner * 0.45)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bodyBottom - corner))
        path.addCurve(
            to: CGPoint(x: rect.minX + corner, y: bodyBottom),
            control1: CGPoint(x: rect.minX, y: bodyBottom - corner * 0.45),
            control2: CGPoint(x: rect.minX + corner * 0.45, y: bodyBottom)
        )

        // Нижний негативный радиус зеркален верхнему.
        path.addLine(to: CGPoint(x: shoulderX, y: bodyBottom))
        path.addCurve(
            to: CGPoint(x: edgeX, y: rect.maxY),
            control1: CGPoint(x: shoulderX + circleControl, y: bodyBottom),
            control2: CGPoint(x: edgeX, y: rect.maxY - circleControl)
        )
        path.closeSubpath()

        return path
    }
}
