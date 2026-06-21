import AppKit

struct PanelGeometry {
    static let peekWidth: CGFloat = 8
    static let edgeTriggerWidth: CGFloat = 5

    let screen: NSScreen
    let visibleWidth: CGFloat
    let height: CGFloat

    init(screen: NSScreen, size: NSSize? = nil) {
        self.screen = screen
        let defaultSize = NSSize(
            width: min(max(screen.frame.width / 3, 320), 560),
            height: screen.visibleFrame.height * 2 / 3
        )
        visibleWidth = size?.width ?? defaultSize.width
        height = size?.height ?? defaultSize.height
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
            y: verticalOrigin,
            width: Self.edgeTriggerWidth,
            height: height
        )
    }

    private var verticalOrigin: CGFloat {
        screen.visibleFrame.midY - height / 2
    }

    private func frame(visibleWidth: CGFloat) -> NSRect {
        return NSRect(
            origin: NSPoint(
                x: screen.frame.maxX - visibleWidth,
                y: verticalOrigin
            ),
            size: NSSize(
                width: visibleWidth,
                height: height
            )
        )
    }
}
