import AppKit
import WranglerCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (menu bar + overlay only, no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar controller
        statusBarController = StatusBarController()

        // Register global hotkeys
        GlobalHotKeyManager.shared.onHotKeyPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.toggleOverlay()
            }
        }
        GlobalHotKeyManager.shared.onNextDisplayPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.moveToNextDisplay()
            }
        }
        GlobalHotKeyManager.shared.onPrevDisplayPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.moveToPreviousDisplay()
            }
        }
        GlobalHotKeyManager.shared.onAutoTilePressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.autoTileCurrentDisplay()
            }
        }
        GlobalHotKeyManager.shared.onMaximizePressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.snapFocusedWindow(preset: "full")
            }
        }
        GlobalHotKeyManager.shared.registerDefaultHotKeys()

        // Start drag-to-snap zones monitor
        SnapZoneMonitor.shared.start()

        // Prompt for Accessibility if not granted yet
        _ = AccessibilityEngine.isTrusted(promptIfNeeded: true)

        print("Wrangler GUI launched. Running in menu bar.")
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregisterAll()
        SnapZoneMonitor.shared.stop()
    }
}
