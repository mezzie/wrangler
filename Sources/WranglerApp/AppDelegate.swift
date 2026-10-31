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

        // Register global hotkey (Option + Space)
        GlobalHotKeyManager.shared.onHotKeyPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.toggleOverlay()
            }
        }
        GlobalHotKeyManager.shared.registerDefaultHotKey()

        // Prompt for Accessibility if not granted yet
        _ = AccessibilityEngine.isTrusted(promptIfNeeded: true)

        print("Wrangler GUI launched. Running in menu bar.")
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregister()
    }
}
