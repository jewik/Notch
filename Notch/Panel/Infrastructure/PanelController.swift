import AppKit
import QuartzCore
import SwiftUI

enum PanelState: Equatable {
    case hidden
    case peek
    case visible
}

private struct FrameAnimation {
    let generation: Int
    let startFrame: NSRect
    let endFrame: NSRect
    let startTime: TimeInterval
    let duration: TimeInterval
    let shouldOrderOut: Bool
}

final class PanelController {
    var onStateChange: ((PanelState) -> Void)?

    private(set) var state: PanelState = .hidden
    private var panel: OverlayPanel?
    private var leftEarPanel: PanelEarPanel?
    private var rightEarPanel: PanelEarPanel?
    private var currentScreen: NSScreen?
    private var animationGeneration = 0
    private var animationDisplayLink: CADisplayLink?
    private var activeAnimation: FrameAnimation?
    private var pendingPeekHide: DispatchWorkItem?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var screenChangeObserver: NSObjectProtocol?
    private let presentation = PanelPresentationModel()
    private let contentMetrics = PanelContentMetrics()

    init() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChanged()
        }
    }

    deinit {
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
        }
    }

    func show(route: PanelRoute = .home, on screen: NSScreen? = nil) {
        cancelPeekHide()
        presentation.route = route
        let targetScreen = screen ?? screenUnderPointer()
        let panel = preparePanel(on: targetScreen)
        resize(
            panel: panel,
            to: .visible,
            frame: geometry(for: targetScreen).visibleFrame(for: presentation.sizePreset)
        )
    }

    func hide() {
        cancelPeekHide()
        guard let panel, let currentScreen, state != .hidden else { return }
        resize(panel: panel, to: .hidden, frame: geometry(for: currentScreen).hiddenFrame)
    }

    func toggle() {
        if state == .visible {
            hide()
        } else {
            show()
        }
    }

    func peek(on screen: NSScreen) {
        guard state != .visible else { return }
        cancelPeekHide()
        let panel = preparePanel(on: screen)
        resize(panel: panel, to: .peek, frame: geometry(for: screen).peekFrame)
    }

    func schedulePeekHide() {
        guard state == .peek else { return }
        cancelPeekHide()

        let workItem = DispatchWorkItem { [weak self] in
            guard self?.state == .peek else { return }
            self?.hide()
        }
        pendingPeekHide = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    func stop() {
        cancelPeekHide()
        removeOutsideClickMonitors()
        cancelFrameAnimation()
        animationGeneration += 1
        presentation.isChromeVisible = false
        presentation.isContentVisible = false
        panel?.orderOut(nil)
        orderOutEarPanels()
        panel = nil
        leftEarPanel = nil
        rightEarPanel = nil
        currentScreen = nil
    }

    private func preparePanel(on screen: NSScreen) -> OverlayPanel {
        contentMetrics.update(for: screen)
        let panel = panel ?? makePanel(on: screen)
        let geometry = geometry(for: screen)

        if currentScreen !== screen {
            currentScreen = screen
            panel.setFrame(geometry.hiddenFrame, display: false)
        }

        prepareEarPanels(for: panel)
        updateEarPanels(for: panel.frame)
        panel.orderFrontRegardless()
        orderFrontEarPanels()
        return panel
    }

    private func makePanel(on screen: NSScreen) -> OverlayPanel {
        let geometry = geometry(for: screen)
        let panel = OverlayPanel(contentRect: geometry.hiddenFrame)
        let contentView = PanelHostingView(rootView: PanelView(
            presentation: presentation,
            contentMetrics: contentMetrics,
            openRoute: { [weak self] route in
                self?.show(route: route, on: self?.currentScreen)
            }
        ))
        contentView.onMouseEntered = { [weak self] in self?.cancelPeekHide() }
        contentView.onMouseExited = { [weak self] in self?.schedulePeekHide() }
        contentView.onMouseDown = { [weak self] in
            guard let self, self.state == .peek else { return }
            self.show(on: self.currentScreen)
        }
        panel.contentView = contentView
        self.panel = panel
        return panel
    }

    private func geometry(for screen: NSScreen) -> PanelGeometry {
        PanelGeometry(screen: screen)
    }

    private func handleScreenParametersChanged() {
        guard let panel else { return }

        let targetScreen = panel.screen ?? currentScreen ?? screenUnderPointer()
        currentScreen = targetScreen
        contentMetrics.update(for: targetScreen)
        cancelFrameAnimation()
        presentation.isContentVisible = false

        let geometry = geometry(for: targetScreen)
        let targetFrame: NSRect
        switch state {
        case .hidden:
            targetFrame = geometry.hiddenFrame
        case .peek:
            targetFrame = geometry.peekFrame
        case .visible:
            targetFrame = geometry.visibleFrame(for: presentation.sizePreset)
        }

        panel.setFrame(targetFrame, display: true)
        updateEarPanels(for: targetFrame)
        presentation.isChromeVisible = state == .visible
        presentation.isContentVisible = state == .visible
    }

    private func resize(panel: OverlayPanel, to newState: PanelState, frame: NSRect) {
        guard state != newState || panel.frame != frame else {
            presentation.isChromeVisible = newState == .visible
            presentation.isContentVisible = newState == .visible
            return
        }

        cancelFrameAnimation()
        animationGeneration += 1
        let shouldKeepChromeVisible = state == .visible && newState == .visible
        presentation.isChromeVisible = shouldKeepChromeVisible
        presentation.isContentVisible = false
        let generation = animationGeneration
        let startFrame = panel.frame
        let isOpening = frame.height > startFrame.height
        state = newState
        updateOutsideClickMonitors(for: newState)
        onStateChange?(newState)

        let duration: TimeInterval = isOpening ? 0.5 : 0.5
        activeAnimation = FrameAnimation(
            generation: generation,
            startFrame: startFrame,
            endFrame: frame,
            startTime: ProcessInfo.processInfo.systemUptime,
            duration: duration,
            shouldOrderOut: newState == .hidden
        )

        let animationScreen = currentScreen ?? panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let displayLink = animationScreen.displayLink(target: self, selector: #selector(updatePanelAnimation(_:)))
        animationDisplayLink = displayLink
        displayLink.add(to: .main, forMode: .common)
    }

    @objc private func updatePanelAnimation(_ displayLink: CADisplayLink) {
        guard let animation = activeAnimation,
              animation.generation == animationGeneration,
              let panel else {
            cancelFrameAnimation()
            return
        }

        let elapsed = displayLink.timestamp - animation.startTime
        let progress = min(max(elapsed / animation.duration, 0), 1)
        let easedProgress = Self.exponentialProgress(progress)
        let interpolatedFrame = Self.interpolateAnchoredFrame(
            from: animation.startFrame,
            to: animation.endFrame,
            progress: easedProgress
        )
        panel.setFrame(interpolatedFrame, display: true)
        updateEarPanels(for: interpolatedFrame)

        guard progress >= 1 else { return }

        panel.setFrame(animation.endFrame, display: true)
        updateEarPanels(for: animation.endFrame)
        if animation.shouldOrderOut {
            panel.orderOut(nil)
            orderOutEarPanels()
        }
        presentation.isChromeVisible = state == .visible
        presentation.isContentVisible = state == .visible
        cancelFrameAnimation()
    }

    private func prepareEarPanels(for panel: OverlayPanel) {
        if leftEarPanel == nil {
            let earPanel = PanelEarPanel(contentRect: .zero, side: .left, contentMetrics: contentMetrics)
            panel.addChildWindow(earPanel, ordered: .above)
            leftEarPanel = earPanel
        }

        if rightEarPanel == nil {
            let earPanel = PanelEarPanel(contentRect: .zero, side: .right, contentMetrics: contentMetrics)
            panel.addChildWindow(earPanel, ordered: .above)
            rightEarPanel = earPanel
        }
    }

    private func updateEarPanels(for panelFrame: NSRect) {
        let earSize = ContinuousCornerProfile(
            expansion: panelFrame.height,
            pointMultiplier: contentMetrics.pointMultiplier
        ).radius
        let earY = panelFrame.maxY - earSize

        leftEarPanel?.setFrame(NSRect(
            x: panelFrame.minX - earSize,
            y: earY,
            width: earSize,
            height: earSize
        ), display: true)

        rightEarPanel?.setFrame(NSRect(
            x: panelFrame.maxX,
            y: earY,
            width: earSize,
            height: earSize
        ), display: true)
    }

    private func orderFrontEarPanels() {
        leftEarPanel?.orderFrontRegardless()
        rightEarPanel?.orderFrontRegardless()
    }

    private func orderOutEarPanels() {
        leftEarPanel?.orderOut(nil)
        rightEarPanel?.orderOut(nil)
    }

    private func cancelFrameAnimation() {
        animationDisplayLink?.invalidate()
        animationDisplayLink = nil
        activeAnimation = nil
    }

    private static func exponentialProgress(_ progress: Double) -> Double {
        let minimum = pow(2.0, -10.0)
        let range = 1.0 - minimum
        return (1.0 - pow(2.0, -10.0 * progress)) / range
    }

    private static func interpolateAnchoredFrame(
        from start: NSRect,
        to end: NSRect,
        progress: Double
    ) -> NSRect {
        func value(_ start: CGFloat, _ end: CGFloat) -> CGFloat {
            start + (end - start) * CGFloat(progress)
        }

        let width = value(start.width, end.width)
        let height = value(start.height, end.height)
        return NSRect(
            x: end.midX - width / 2,
            y: end.maxY - height,
            width: width,
            height: height
        )
    }

    private func updateOutsideClickMonitors(for state: PanelState) {
        removeOutsideClickMonitors()
        guard state == .visible else { return }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.handlePossibleOutsideClick(at: NSEvent.mouseLocation)
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handlePossibleOutsideClick(at: NSEvent.mouseLocation)
            return event
        }
    }

    private func handlePossibleOutsideClick(at location: NSPoint) {
        guard state == .visible, let panel, !panel.frame.contains(location) else { return }
        hide()
    }

    private func removeOutsideClickMonitors() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }

    private func cancelPeekHide() {
        pendingPeekHide?.cancel()
        pendingPeekHide = nil
    }

    private func screenUnderPointer() -> NSScreen {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(location, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}

private final class OverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isMovable = false
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class PanelEarPanel: NSPanel {
    init(contentRect: NSRect, side: PanelEarSide, contentMetrics: PanelContentMetrics) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        isMovable = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        contentView = NSHostingView(rootView: PanelEarView(
            side: side,
            contentMetrics: contentMetrics
        ))
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class PanelHostingView: NSHostingView<PanelView> {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    var onMouseDown: (() -> Void)?

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
        onMouseEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }
}
