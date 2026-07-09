import AppKit

final class EdgeTriggerService {
    private let onEnter: (NSScreen) -> Void
    private let onExit: () -> Void
    private let onClick: (NSScreen) -> Void
    private let onFileDragEnter: (NSScreen) -> Void

    private var sensorPanels: [EdgeSensorPanel] = []
    private var screenChangeObserver: NSObjectProtocol?
    private var isInteractionEnabled = true

    init(
        onEnter: @escaping (NSScreen) -> Void,
        onExit: @escaping () -> Void,
        onClick: @escaping (NSScreen) -> Void,
        onFileDragEnter: @escaping (NSScreen) -> Void
    ) {
        self.onEnter = onEnter
        self.onExit = onExit
        self.onClick = onClick
        self.onFileDragEnter = onFileDragEnter
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

    func setInteractionEnabled(_ isEnabled: Bool) {
        isInteractionEnabled = isEnabled
        sensorPanels.forEach { $0.ignoresMouseEvents = !isEnabled }
    }

    private func rebuildSensors() {
        sensorPanels.forEach { $0.orderOut(nil) }
        sensorPanels = NSScreen.screens.map { screen in
            let panel = EdgeSensorPanel(frame: PanelGeometry(screen: screen).edgeTriggerFrame)
            panel.ignoresMouseEvents = !isInteractionEnabled
            panel.sensorView.onEnter = { [weak self] in
                self?.onEnter(screen)
            }
            panel.sensorView.onExit = { [weak self] in self?.onExit() }
            panel.sensorView.onClick = { [weak self] in
                self?.onClick(screen)
            }
            panel.sensorView.onFileDragEnter = { [weak self] in
                self?.onFileDragEnter(screen)
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
    var onFileDragEnter: (() -> Void)?

    private var trackingAreaReference: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

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

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard acceptsFileDrag(sender) else { return [] }
        onFileDragEnter?()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptsFileDrag(sender) ? .copy : []
    }

    private func acceptsFileDrag(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }
}
