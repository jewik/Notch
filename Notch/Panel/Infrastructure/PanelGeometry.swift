import AppKit

struct PanelGeometry {
    static let edgeTriggerHeight: CGFloat = 25

    let screen: NSScreen

    init(screen: NSScreen) {
        self.screen = screen
    }

    func visibleFrame(for preset: PanelSizePreset) -> NSRect {
        frame(for: preset)
    }

    var peekFrame: NSRect {
        frame(for: .peek)
    }

    var hiddenFrame: NSRect {
        frame(for: .hidden)
    }

    var edgeTriggerFrame: NSRect {
        let width = PanelSizePreset.hidden.width(for: screen)
        let height = PanelDisplayScale.points(Self.edgeTriggerHeight, for: screen)
        return NSRect(
            x: horizontalOrigin(for: width),
            y: screen.frame.maxY - height,
            width: width,
            height: height
        )
    }

    private func frame(for preset: PanelSizePreset) -> NSRect {
        frame(
            width: preset.width(for: screen),
            visibleHeight: preset.height(for: screen)
        )
    }

    private func horizontalOrigin(for width: CGFloat) -> CGFloat {
        screen.frame.midX - width / 2
    }

    private func frame(width: CGFloat, visibleHeight: CGFloat) -> NSRect {
        return NSRect(
            origin: NSPoint(
                x: horizontalOrigin(for: width),
                y: screen.frame.maxY - visibleHeight
            ),
            size: NSSize(
                width: width,
                height: visibleHeight
            )
        )
    }
}
