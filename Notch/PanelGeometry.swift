import AppKit

struct PanelGeometry {
    static let peekHeight: CGFloat = 8
    static let edgeTriggerHeight: CGFloat = 5

    let screen: NSScreen
    let visibleWidth: CGFloat
    let height: CGFloat
    
    let scale: CGFloat

    private var compactWidth: CGFloat {
        screen.frame.width / 9
    }

    init(screen: NSScreen, size: NSSize? = nil) {
        self.screen = screen
        let defaultSize = PanelSizePreset.standard.size(for: screen)
        visibleWidth = size?.width ?? defaultSize.width
        height = size?.height ?? defaultSize.height
        
        scale = screen.backingScaleFactor
    }

    var visibleFrame: NSRect {
        frame(width: visibleWidth, visibleHeight: height)
    }

    var peekFrame: NSRect {
//        frame(width: compactWidth, visibleHeight: Self.peekHeight)
        frame(width: CGFloat(400 / scale), visibleHeight: CGFloat(80 / scale))
    }

    var hiddenFrame: NSRect {
        frame(width: CGFloat(360 / scale), visibleHeight: CGFloat(74 / scale))
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
