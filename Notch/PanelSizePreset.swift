import AppKit

/// Именованный конечный размер панели.
///
/// Чтобы добавить вариант, объявите новый `static let` и включите его в `all`.
struct PanelSizePreset {
    let name: String

    private let resolveSize: (NSScreen) -> NSSize

    init(name: String, width: CGFloat, height: CGFloat) {
        self.name = name
        resolveSize = { _ in NSSize(width: width, height: height) }
    }

    private init(name: String, resolveSize: @escaping (NSScreen) -> NSSize) {
        self.name = name
        self.resolveSize = resolveSize
    }

    func size(for screen: NSScreen) -> NSSize {
        resolveSize(screen)
    }

    static let compact = PanelSizePreset(name: "compact", width: 420, height: 280)

    /// Сохраняет текущий адаптивный размер панели.
    static let standard = PanelSizePreset(name: "standard") { screen in
        NSSize(
            width: min(max(screen.frame.width / 3, 320), 560),
            height: screen.visibleFrame.height / 3
        )
    }

    static let large = PanelSizePreset(name: "large", width: 720, height: 480)

    static let all: [PanelSizePreset] = [
        .compact,
        .standard,
        .large,
    ]
}
