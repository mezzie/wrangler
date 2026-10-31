import AppKit
import WranglerCore

@MainActor
public final class StatusBarController {
    private var statusItem: NSStatusItem!
    private let coordinator = WindowManagerCoordinator.shared

    public init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3.square", accessibilityDescription: "Wrangler")
            button.imagePosition = .imageOnly
        }

        buildMenu()
    }

    public func buildMenu() {
        let menu = NSMenu(title: "Wrangler")

        let showOverlayItem = NSMenuItem(
            title: "Show Grid Overlay",
            action: #selector(showOverlayClicked),
            keyEquivalent: " "
        )
        showOverlayItem.keyEquivalentModifierMask = [.option]
        showOverlayItem.target = self
        menu.addItem(showOverlayItem)

        menu.addItem(NSMenuItem.separator())

        // Presets submenu
        let presetsMenu = NSMenu(title: "Snap Presets")

        let presets: [(String, String, String)] = [
            ("Maximize", "full", "M"),
            ("Left Half", "left-half", "←"),
            ("Right Half", "right-half", "→"),
            ("Top Half", "top-half", "↑"),
            ("Bottom Half", "bottom-half", "↓"),
            ("Center", "center", "C")
        ]

        for (title, id, _) in presets {
            let item = NSMenuItem(title: title, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.representedObject = id
            item.target = self
            presetsMenu.addItem(item)
        }

        let presetsItem = NSMenuItem(title: "Snap Presets", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsMenu
        menu.addItem(presetsItem)

        // Undo
        let undoItem = NSMenuItem(
            title: "Undo Last Snap",
            action: #selector(undoClicked),
            keyEquivalent: "z"
        )
        undoItem.keyEquivalentModifierMask = [.command, .option]
        undoItem.target = self
        menu.addItem(undoItem)

        menu.addItem(NSMenuItem.separator())

        // Check Permissions
        let permItem = NSMenuItem(title: "Check Accessibility Permissions...", action: #selector(checkPermClicked), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Wrangler", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func showOverlayClicked() {
        coordinator.showOverlay()
    }

    @objc private func presetClicked(_ sender: NSMenuItem) {
        guard let presetID = sender.representedObject as? String else { return }
        coordinator.snapFocusedWindow(preset: presetID)
    }

    @objc private func undoClicked() {
        coordinator.undoLastSnap()
    }

    @objc private func checkPermClicked() {
        let trusted = AccessibilityEngine.isTrusted(promptIfNeeded: true)
        let alert = NSAlert()
        if trusted {
            alert.messageText = "Accessibility Granted"
            alert.informativeText = "Wrangler has full accessibility permissions."
            alert.alertStyle = .informational
        } else {
            alert.messageText = "Accessibility Missing"
            alert.informativeText = "Please enable Wrangler in System Settings -> Privacy & Security -> Accessibility."
            alert.alertStyle = .warning
        }
        alert.runModal()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
