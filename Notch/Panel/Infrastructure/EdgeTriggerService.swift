import AppKit

final class EdgeTriggerService {
    private let onEnter: (NSScreen) -> Void
    private let onExit: () -> Void
    private let onClick: (NSScreen) -> Void

    private var sensorPanels: [EdgeSensorPanel] = []
    private var screenChangeObserver: NSObjectProtocol?

    init(
        onEnter: @escaping (NSScreen) -> Void,
        onExit: @escaping () -> Void,
        onClick: @escaping (NSScreen) -> Void
    ) {
        self.onEnter = onEnter
        self.onExit = onExit
        self.onClick = onClick
    }

    func start() {
        rebuildSensors()
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildSensors()
        }
    }

    func stop() {
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
            self.screenChangeObserver = nil
        }
        sensorPanels.forEach { $0.orderOut(nil) }
        sensorPanels.removeAll()
    }

    private func rebuildSensors() {
        sensorPanels.forEach { $0.orderOut(nil) }
        sensorPanels = NSScreen.screens.map { screen in
            let panel = EdgeSensorPanel(frame: PanelGeometry(screen: screen).edgeTriggerFrame)
            panel.sensorView.onEnter = { [weak self, weak screen] in
                guard let screen else { return }
                self?.onEnter(screen)
            }
            panel.sensorView.onExit = { [weak self] in self?.onExit() }
            panel.sensorView.onClick = { [weak self, weak screen] in
                guard let screen else { return }
                self?.onClick(screen)
            }
            panel.orderFrontRegardless()
            return panel
        }
    }
}

private final class EdgeSensorPanel: NSPanel {
    let sensorView = EdgeSensorView()

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        contentView = sensorView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class EdgeSensorView: NSView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    var onClick: (() -> Void)?

    private var trackingAreaReference: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference {
            removeTrackingArea(trackingAreaReference)
        }

        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaReference = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        onEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onExit?()
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
