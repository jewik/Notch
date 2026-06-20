import AppKit

struct PanelGeometry {
    static let cornerRadius: CGFloat = 28
    static let edgeMergeDepth: CGFloat = 30
    static let peekWidth: CGFloat = 8
    static let edgeTriggerWidth: CGFloat = 2

    let screen: NSScreen
    let visibleWidth: CGFloat
    let height: CGFloat

    init(screen: NSScreen) {
        self.screen = screen
        visibleWidth = min(max(screen.frame.width / 3, 320), 560)
        height = min(max(screen.frame.height * 2 / 3, 420), screen.visibleFrame.height)
    }

    var visibleFrame: NSRect {
        frame(visibleWidth: visibleWidth)
    }

    var peekFrame: NSRect {
        frame(visibleWidth: Self.peekWidth)
    }

    var hiddenFrame: NSRect {
        frame(visibleWidth: 0)
    }

    var edgeTriggerFrame: NSRect {
        NSRect(
            x: screen.frame.maxX - Self.edgeTriggerWidth,
            y: verticalOrigin - Self.edgeMergeDepth,
            width: Self.edgeTriggerWidth,
            height: height + Self.edgeMergeDepth * 2
        )
    }

    private var verticalOrigin: CGFloat {
        screen.visibleFrame.midY - height / 2
    }

    private func frame(visibleWidth: CGFloat) -> NSRect {
        let mergeRadius = min(Self.edgeMergeDepth, visibleWidth / 2)
        return NSRect(
            origin: NSPoint(
                x: screen.frame.maxX - visibleWidth,
                y: verticalOrigin - mergeRadius
            ),
            size: NSSize(
                width: visibleWidth,
                height: height + mergeRadius * 2
            )
        )
    }
}
