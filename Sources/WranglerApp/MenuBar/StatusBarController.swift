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

        // 1. Overlay
        let showOverlayItem = NSMenuItem(
            title: "Show Grid Overlay",
            action: #selector(showOverlayClicked),
            keyEquivalent: " "
        )
        showOverlayItem.keyEquivalentModifierMask = [.option]
        showOverlayItem.target = self
        menu.addItem(showOverlayItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Display Hop
        let nextDispItem = NSMenuItem(
            title: "Move to Next Display",
            action: #selector(nextDisplayClicked),
            keyEquivalent: String(utf16CodeUnits: [unichar(NSRightArrowFunctionKey)], count: 1)
        )
        nextDispItem.keyEquivalentModifierMask = [.control, .option]
        nextDispItem.target = self
        menu.addItem(nextDispItem)

        let prevDispItem = NSMenuItem(
            title: "Move to Previous Display",
            action: #selector(prevDisplayClicked),
            keyEquivalent: String(utf16CodeUnits: [unichar(NSLeftArrowFunctionKey)], count: 1)
        )
        prevDispItem.keyEquivalentModifierMask = [.control, .option]
        prevDispItem.target = self
        menu.addItem(prevDispItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Presets Submenu
        let presetsMenu = NSMenu(title: "Snap Presets")

        let allPresets = NamedLayout.standardPresets
        for layout in allPresets {
            let item = NSMenuItem(title: layout.name, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.representedObject = layout.id
            item.target = self
            presetsMenu.addItem(item)
        }

        let presetsItem = NSMenuItem(title: "Snap Presets", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsMenu
        menu.addItem(presetsItem)

        // 4. Undo
        let undoItem = NSMenuItem(
            title: "Undo Last Snap",
            action: #selector(undoClicked),
            keyEquivalent: "z"
        )
        undoItem.keyEquivalentModifierMask = [.command, .option]
        undoItem.target = self
        menu.addItem(undoItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(preferencesClicked),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = [.command]
        prefsItem.target = self
        menu.addItem(prefsItem)

        // 6. Check Permissions
        let permItem = NSMenuItem(title: "Check Accessibility Permissions...", action: #selector(checkPermClicked), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())

        // 7. Quit
        let quitItem = NSMenuItem(title: "Quit Wrangler", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func showOverlayClicked() {
        coordinator.showOverlay()
    }

    @objc private func nextDisplayClicked() {
        coordinator.moveToNextDisplay()
    }

    @objc private func prevDisplayClicked() {
        coordinator.moveToPreviousDisplay()
    }

    @objc private func presetClicked(_ sender: NSMenuItem) {
        guard let presetID = sender.representedObject as? String else { return }
        coordinator.snapFocusedWindow(preset: presetID)
    }

    @objc private func undoClicked() {
        coordinator.undoLastSnap()
    }

    @objc private func preferencesClicked() {
        PreferencesWindowController.shared.showPreferences()
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
