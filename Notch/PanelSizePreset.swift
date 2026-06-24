import AppKit

/// Именованный конечный размер панели.
///
/// Новый вариант добавляется как `static let` и включается в `all`.
struct PanelSizePreset {
    typealias DimensionResolver = (NSScreen) -> CGFloat

    let name: String

    private let resolveWidth: DimensionResolver
    private let resolveHeight: DimensionResolver

    init(name: String, width: CGFloat, height: CGFloat) {
        self.name = name
        resolveWidth = { _ in width }
        resolveHeight = { _ in height }
    }

    init(
        name: String,
        width: @escaping DimensionResolver,
        height: @escaping DimensionResolver
    ) {
        self.name = name
        resolveWidth = width
        resolveHeight = height
    }

    func width(for screen: NSScreen) -> CGFloat {
        resolveWidth(screen)
    }

    func height(for screen: NSScreen) -> CGFloat {
        resolveHeight(screen)
    }

    static let hidden = PanelSizePreset(
        name: "hidden",
//        width: { 360 / $0.backingScaleFactor },
//        height: { 60 / $0.backingScaleFactor }
        width: CGFloat(360 / 2),
        height: CGFloat(60 / 2)
    )

    static let peek = PanelSizePreset(
        name: "peek",
//        width: { 400 / $0.backingScaleFactor },
//        height: { 80 / $0.backingScaleFactor }
        width: CGFloat(400 / 2),
        height: CGFloat(80 / 2)
    )

    static let home = PanelSizePreset(
        name: "home",
        width: { 1000 / $0.backingScaleFactor },
        height: { 200 / $0.backingScaleFactor }
    )

    static let all: [PanelSizePreset] = [
        .hidden,
        .peek,
        .home,
    ]
}
