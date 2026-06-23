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
        width: { 360 / $0.backingScaleFactor },
        height: { 60 / $0.backingScaleFactor }
    )

    static let peek = PanelSizePreset(
        name: "peek",
        width: { 400 / $0.backingScaleFactor },
        height: { 80 / $0.backingScaleFactor }
    )

    static let visible = PanelSizePreset(
        name: "visible",
        width: { min(max($0.frame.width / 3, 320), 560) },
        height: { $0.visibleFrame.height / 3 }
    )

    static let all: [PanelSizePreset] = [
        .hidden,
        .peek,
        .visible,
    ]
}
