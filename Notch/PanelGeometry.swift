import AppKit

struct PanelGeometry {
    static let peekWidth: CGFloat = 8
    static let edgeTriggerWidth: CGFloat = 5

    let screen: NSScreen
    let visibleWidth: CGFloat
    let height: CGFloat

    private var compactHeight: CGFloat {
        screen.frame.height / 5
    }

    init(screen: NSScreen, size: NSSize? = nil) {
        self.screen = screen
        let defaultSize = NSSize(
            width: min(max(screen.frame.width / 4, 320), 560),
            height: screen.visibleFrame.height * 2 / 3
        )
        visibleWidth = size?.width ?? defaultSize.width
        height = size?.height ?? defaultSize.height
    }

    var visibleFrame: NSRect {
        frame(visibleWidth: visibleWidth, height: height)
    }

    var peekFrame: NSRect {
        frame(visibleWidth: Self.peekWidth, height: compactHeight)
    }

    var hiddenFrame: NSRect {
        frame(visibleWidth: 0, height: compactHeight)
    }

    var edgeTriggerFrame: NSRect {
        NSRect(
            x: screen.frame.maxX - Self.edgeTriggerWidth,
            y: verticalOrigin(for: compactHeight),
            width: Self.edgeTriggerWidth,
            height: compactHeight
        )
    }

    private func verticalOrigin(for height: CGFloat) -> CGFloat {
        screen.frame.midY - height / 2
    }

    private func frame(visibleWidth: CGFloat, height: CGFloat) -> NSRect {
        return NSRect(
            origin: NSPoint(
                x: screen.frame.maxX - visibleWidth,
                y: verticalOrigin(for: height)
            ),
            size: NSSize(
                width: visibleWidth,
                height: height
            )
        )
    }
}
