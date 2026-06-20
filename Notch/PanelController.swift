import AppKit
import SwiftUI

enum PanelState: Equatable {
    case hidden
    case peek
    case visible
}

final class PanelController {
    var onStateChange: ((PanelState) -> Void)?

    private(set) var state: PanelState = .hidden
    private var panel: OverlayPanel?
    private var currentScreen: NSScreen?
    private var animationGeneration = 0
    private var pendingPeekHide: DispatchWorkItem?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    func show(on screen: NSScreen? = nil) {
        cancelPeekHide()
        let targetScreen = screen ?? screenUnderPointer()
        let panel = preparePanel(on: targetScreen)
        transition(to: .visible, panel: panel, frame: PanelGeometry(screen: targetScreen).visibleFrame)
    }

    func hide() {
        cancelPeekHide()
        guard let panel, let currentScreen, state != .hidden else { return }
        transition(to: .hidden, panel: panel, frame: PanelGeometry(screen: currentScreen).hiddenFrame)
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
        transition(to: .peek, panel: panel, frame: PanelGeometry(screen: screen).peekFrame)
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
        animationGeneration += 1
        panel?.orderOut(nil)
        panel = nil
        currentScreen = nil
    }

    private func preparePanel(on screen: NSScreen) -> OverlayPanel {
        let panel = panel ?? makePanel(on: screen)
        let geometry = PanelGeometry(screen: screen)

        if currentScreen !== screen {
            currentScreen = screen
            panel.setFrame(geometry.hiddenFrame, display: false)
        }

        panel.orderFrontRegardless()
        return panel
    }

    private func makePanel(on screen: NSScreen) -> OverlayPanel {
        let geometry = PanelGeometry(screen: screen)
        let panel = OverlayPanel(contentRect: geometry.hiddenFrame)
        let contentView = PanelHostingView(rootView: PanelView())
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

    private func transition(to newState: PanelState, panel: OverlayPanel, frame: NSRect) {
        guard state != newState || panel.frame != frame else { return }

        animationGeneration += 1
        let generation = animationGeneration
        state = newState
        updateOutsideClickMonitors(for: newState)
        onStateChange?(newState)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self, weak panel] in
            DispatchQueue.main.async {
                guard let self, self.animationGeneration == generation, self.state == newState else { return }
                if newState == .hidden {
                    panel?.orderOut(nil)
                }
            }
        }
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
