import AppKit

/// Именованный конечный размер панели.
///
/// Новый вариант добавляется как `static let` и включается в `all`.
struct PanelSizePreset {
    let name: String
    let width: CGFloat
    let height: CGFloat

    init(name: String, width: CGFloat, height: CGFloat) {
        self.name = name
        self.width = width
        self.height = height
    }

    func width(for screen: NSScreen) -> CGFloat {
        PanelDisplayScale.points(width, for: screen)
    }

    func height(for screen: NSScreen) -> CGFloat {
        PanelDisplayScale.points(height, for: screen)
    }

    // exact notch size on macbook pro 14 inch
    static let hidden = PanelSizePreset(
        name: "hidden",
        width: 160,
        height: 28
    )

    static let peek = PanelSizePreset(
        name: "peek",
        width: 200,
        height: 38
    )

    static let home = PanelSizePreset(
        name: "home",
        width: 500,
        height: 100
    )

    static let sysMonitor = PanelSizePreset(
        name: "sysmonitor",
        width: 340,
        height: 120
    )

    static let clipboard = PanelSizePreset(
        name: "clipboard",
        width: 500,
        height: 400
    )

    static let all: [PanelSizePreset] = [
        .hidden,
        .peek,
        .home,
        .sysMonitor,
        .clipboard,
    ]
}
