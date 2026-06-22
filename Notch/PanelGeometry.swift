import AppKit

struct PanelGeometry {
    static let peekHeight: CGFloat = 8
    static let edgeTriggerHeight: CGFloat = 5

    let screen: NSScreen
    let visibleWidth: CGFloat
    let height: CGFloat

    private var compactWidth: CGFloat {
        screen.frame.width / 8
    }

    init(screen: NSScreen, size: NSSize? = nil) {
        self.screen = screen
        let defaultSize = NSSize(
            width: min(max(screen.frame.width / 3, 320), 560),
            height: screen.visibleFrame.height / 3
        )
        visibleWidth = size?.width ?? defaultSize.width
        height = size?.height ?? defaultSize.height
    }

    var visibleFrame: NSRect {
        frame(width: visibleWidth, visibleHeight: height)
    }

    var peekFrame: NSRect {
        frame(width: compactWidth, visibleHeight: Self.peekHeight)
    }

    var hiddenFrame: NSRect {
        frame(width: compactWidth, visibleHeight: 0)
    }

    var edgeTriggerFrame: NSRect {
        NSRect(
            x: horizontalOrigin(for: compactWidth),
            y: screen.frame.maxY - Self.edgeTriggerHeight,
            width: compactWidth,
            height: Self.edgeTriggerHeight
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
