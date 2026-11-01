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
        GlobalHotKeyManager.shared.onUndoPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.undoLastSnap()
            }
        }
        GlobalHotKeyManager.shared.onSwapPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.swapTopTwoWindows()
            }
        }
        GlobalHotKeyManager.shared.onNumpadPressed = { preset in
            Task { @MainActor in
                WindowManagerCoordinator.shared.snapFocusedWindow(preset: preset)
            }
        }
        GlobalHotKeyManager.shared.onFocusDirectionPressed = { dir in
            Task { @MainActor in
                WindowManagerCoordinator.shared.focusAdjacentWindow(in: dir)
            }
        }
        GlobalHotKeyManager.shared.onCycleSameAppPressed = {
            Task { @MainActor in
                WindowManagerCoordinator.shared.cycleSameAppWindows()
            }
        }
        GlobalHotKeyManager.shared.registerFromSettings()

        // Start drag-to-snap zones monitor
        SnapZoneMonitor.shared.start()

        // Check for updates in background (silent)
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await UpdateManager.shared.checkForUpdates(silent: true)
        }

        // Prompt for Accessibility if not granted yet
        _ = AccessibilityEngine.isTrusted(promptIfNeeded: true)

        print("Wrangler GUI launched. Running in menu bar.")
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregisterAll()
        SnapZoneMonitor.shared.stop()
    }
}
