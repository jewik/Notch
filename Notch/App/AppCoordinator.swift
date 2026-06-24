import AppKit

final class AppCoordinator: NSObject {
    private let shortcutService = ShortcutService()
    private let panelController = PanelController()
    private lazy var edgeTriggerService = EdgeTriggerService(
        onEnter: { [weak self] screen in self?.panelController.peek(on: screen) },
        onExit: { [weak self] in self?.panelController.schedulePeekHide() },
        onClick: { [weak self] screen in self?.panelController.show(on: screen) }
    )

    private var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?

    func start() {
        configureMenuBar()
        ClipboardFeature.shared.start()

        shortcutService.onToggle = { [weak self] in
            self?.panelController.toggle()
        }
        shortcutService.onDismiss = { [weak self] in
            self?.panelController.hide()
        }
        shortcutService.start()

        panelController.onStateChange = { [weak self] state in
            guard let self else { return }
            self.toggleMenuItem?.title = state == .visible ? "Скрыть" : "Показать"
            self.shortcutService.setDismissShortcutEnabled(state == .visible)
        }
        edgeTriggerService.start()
    }

    func stop() {
        ClipboardFeature.shared.stop()
        edgeTriggerService.stop()
        shortcutService.stop()
        panelController.stop()

        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    private func configureMenuBar() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Notch")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Показать", action: #selector(togglePanel), keyEquivalent: "v")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Завершить Notch", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
        toggleMenuItem = toggleItem
    }

    @objc private func togglePanel() {
        panelController.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
