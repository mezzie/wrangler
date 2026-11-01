import AppKit
import SwiftUI
import WranglerCore

@MainActor
public final class WindowManagerCoordinator: ObservableObject {
    public static let shared = WindowManagerCoordinator()

    private let accessibilityEngine = AccessibilityEngine()
    private let displayManager = DisplayManager()
    private let windowHistory = WindowHistory()

    private let previewPanel = TargetPreviewPanel()
    private var overlayPanel: GridOverlayPanel?
    private let selectionModel = GridSelectionModel()

    private var currentTargetElement: AXUIElement?
    private var currentTarget: WindowTarget?
    private var activeScreen: ScreenInfo?
    private var lastActiveApp: NSRunningApplication?

    // Cycling state
    private var lastPresetInvoked: String?
    private var lastPresetTimestamp: Date?

    private init() {
        setupSelectionCallbacks()
        setupAppTracking()
    }

    private func setupAppTracking() {
        let current = NSWorkspace.shared.frontmostApplication
        if current?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            lastActiveApp = current
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                MainActor.assumeIsolated {
                    self?.lastActiveApp = app
                }
            }
        }
    }

    private func resolveTargetApp() -> NSRunningApplication? {
        let front = NSWorkspace.shared.frontmostApplication
        if let front = front, front.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            return front
        }
        return lastActiveApp
    }

    private func setupSelectionCallbacks() {
        selectionModel.onSelectionChanged = { [weak self] selection in
            self?.handleSelectionChanged(selection)
        }

        selectionModel.onSelectionCommitted = { [weak self] selection in
            self?.handleSelectionCommitted(selection)
        }

        selectionModel.onCancel = { [weak self] in
            self?.dismissOverlay()
        }
    }

    public func toggleOverlay() {
        if overlayPanel?.isVisible == true {
            dismissOverlay()
        } else {
            showOverlay()
        }
    }

    public func showOverlay() {
        guard AccessibilityEngine.isTrusted() else {
            print("Notice: Accessibility permission not granted yet.")
            return
        }

        let appToSnap = resolveTargetApp()

        // Capture target window before HUD display using CoreGraphics Z-order
        do {
            let (element, target) = try accessibilityEngine.getTopmostWindowTarget(preferredApp: appToSnap)
            self.currentTargetElement = element
            self.currentTarget = target
        } catch {
            print("Notice: No target window found: \(error.localizedDescription)")
            self.currentTargetElement = nil
            self.currentTarget = nil
        }

        guard let screen = displayManager.currentScreen() else {
            print("Error: Could not determine active display.")
            return
        }
        self.activeScreen = screen

        let allScreens = displayManager.getScreens()

        let interactiveView = GridInteractiveView(
            model: selectionModel,
            appName: currentTarget?.appName,
            onUndo: { [weak self] in
                self?.undoLastSnap()
            },
            onHopNextScreen: { [weak self] in
                self?.moveToNextDisplay()
            },
            onAutoTile: { [weak self] in
                self?.autoTileCurrentDisplay()
            },
            hasMultipleScreens: allScreens.count > 1
        )

        let panel = GridOverlayPanel(rootView: AnyView(interactiveView))
        self.overlayPanel = panel

        panel.show(on: screen, at: NSEvent.mouseLocation)
    }

    public func dismissOverlay() {
        overlayPanel?.hide()
        previewPanel.hide()
        selectionModel.reset()

        if let target = currentTarget {
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        }
    }

    private func handleSelectionChanged(_ selection: GridSelection) {
        guard let screen = activeScreen else { return }
        let targetRectAX = GridMath.calculateRect(
            for: selection,
            in: screen.axVisibleFrame,
            config: selectionModel.config
        )
        let cocoaRect = displayManager.axToCocoa(rect: targetRectAX)
        previewPanel.updateFrame(cocoaRect)
    }

    private func handleSelectionCommitted(_ selection: GridSelection) {
        guard let screen = activeScreen else {
            dismissOverlay()
            return
        }

        let targetRectAX = GridMath.calculateRect(
            for: selection,
            in: screen.axVisibleFrame,
            config: selectionModel.config
        )

        previewPanel.hide()
        overlayPanel?.hide()
        selectionModel.reset()

        if let element = currentTargetElement, let target = currentTarget {
            windowHistory.push(pid: target.pid, frame: target.frame)
            do {
                try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
            } catch {
                print("Failed to snap window: \(error.localizedDescription)")
            }

            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        }
    }

    public func snapFocusedWindow(preset: String) {
        let settings = AppSettings.load()
        var effectivePreset = preset

        // Check for repeated shortcut cycling
        let now = Date()
        if settings.cycleRepeatedSnaps,
           let last = lastPresetInvoked,
           let ts = lastPresetTimestamp,
           now.timeIntervalSince(ts) < 1.5 {
            effectivePreset = NamedLayout.nextCycledPreset(for: last)
        }
        lastPresetInvoked = effectivePreset
        lastPresetTimestamp = now

        guard let screen = displayManager.currentScreen(),
              let layout = NamedLayout.standardPresets.first(where: { $0.id == effectivePreset }) else {
            return
        }

        let appToSnap = resolveTargetApp()

        do {
            let (element, target) = try accessibilityEngine.getTopmostWindowTarget(preferredApp: appToSnap)
            let config = GridConfig(
                columns: layout.config.columns,
                rows: layout.config.rows,
                gap: settings.gap,
                outerMargin: settings.outerMargin
            )
            let targetRectAX = GridMath.calculateRect(
                for: layout.selection,
                in: screen.axVisibleFrame,
                config: config
            )
            windowHistory.push(pid: target.pid, frame: target.frame)
            try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        } catch {
            print("Snap preset error: \(error.localizedDescription)")
        }
    }

    public func moveToNextDisplay() {
        let appToSnap = resolveTargetApp()
        do {
            let (element, target) = try accessibilityEngine.getTopmostWindowTarget(preferredApp: appToSnap)
            guard let currentScreen = displayManager.screen(forWindowAXFrame: target.frame),
                  let nextScreen = displayManager.nextScreen(from: currentScreen) else {
                return
            }
            let targetRectAX = displayManager.mapAXFrame(target.frame, from: currentScreen, to: nextScreen)
            windowHistory.push(pid: target.pid, frame: target.frame)
            try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
            dismissOverlay()
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        } catch {
            print("Move to next display error: \(error.localizedDescription)")
        }
    }

    public func moveToPreviousDisplay() {
        let appToSnap = resolveTargetApp()
        do {
            let (element, target) = try accessibilityEngine.getTopmostWindowTarget(preferredApp: appToSnap)
            guard let currentScreen = displayManager.screen(forWindowAXFrame: target.frame),
                  let prevScreen = displayManager.previousScreen(from: currentScreen) else {
                return
            }
            let targetRectAX = displayManager.mapAXFrame(target.frame, from: currentScreen, to: prevScreen)
            windowHistory.push(pid: target.pid, frame: target.frame)
            try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
            dismissOverlay()
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        } catch {
            print("Move to previous display error: \(error.localizedDescription)")
        }
    }

    /// Automatically tiles all open windows on the active display (AeroSpace / i3 style)
    public func autoTileCurrentDisplay() {
        guard let screen = displayManager.currentScreen() else { return }
        let settings = AppSettings.load()

        let windows = accessibilityEngine.getVisibleWindows(on: screen)
        guard !windows.isEmpty else {
            print("Notice: No visible windows found on display to auto-tile.")
            return
        }

        let frames = AutoTileEngine.calculateFrames(
            count: windows.count,
            in: screen.axVisibleFrame,
            gap: settings.gap,
            outerMargin: settings.outerMargin
        )

        for (index, item) in windows.enumerated() {
            guard index < frames.count else { break }
            let targetFrame = frames[index]
            windowHistory.push(pid: item.target.pid, frame: item.target.frame)
            do {
                try accessibilityEngine.setWindowFrame(targetFrame, element: item.element)
            } catch {
                print("Failed to auto-tile window '\(item.target.appName ?? "")': \(error.localizedDescription)")
            }
        }

        // Keep topmost window focused so subsequent hotkeys target it
        if let first = windows.first {
            NSRunningApplication(processIdentifier: first.target.pid)?.activate(options: .activateIgnoringOtherApps)
        }

        dismissOverlay()
    }

    /// Swaps the positions of the two frontmost windows on the active display
    public func swapTopTwoWindows() {
        guard let screen = displayManager.currentScreen() else { return }
        do {
            try accessibilityEngine.swapTopTwoWindows(on: screen)
        } catch {
            print("Swap windows error: \(error.localizedDescription)")
        }
    }

    /// Focuses adjacent window in direction (Vim HJKL navigation)
    public func focusAdjacentWindow(in direction: FocusDirection) {
        guard let screen = displayManager.currentScreen() else { return }
        accessibilityEngine.focusAdjacentWindow(in: direction, on: screen)
    }

    /// Cycles through open windows of active app (⌃ ⌥ `)
    public func cycleSameAppWindows() {
        accessibilityEngine.cycleSameAppWindows()
    }

    /// Returns current top on-screen windows for preview in Preferences
    public func getDetectedOnScreenWindows() -> [(element: AXUIElement, target: WindowTarget)] {
        guard let screen = displayManager.currentScreen() else { return [] }
        return accessibilityEngine.getTopOnScreenWindows(on: screen)
    }

    /// Captures all visible windows on the active display as a named workspace (Rectangle Pro model)
    public func saveCurrentWorkspace(name: String) {
        guard let screen = displayManager.currentScreen() else { return }
        // Capture only top on-screen windows (not occluded/hidden apps)
        let windows = accessibilityEngine.getTopOnScreenWindows(on: screen)
        guard !windows.isEmpty else {
            print("Notice: No visible windows found to save in workspace.")
            return
        }

        var seenBundleIDs = Set<String>()
        var slots: [AppSlot] = []

        for item in windows {
            guard let bid = item.target.bundleID, !seenBundleIDs.contains(bid) else { continue }
            seenBundleIDs.insert(bid)

            slots.append(AppSlot(
                bundleID: bid,
                appName: item.target.appName ?? bid,
                frame: item.target.frame
            ))
        }

        guard !slots.isEmpty else { return }

        var settings = AppSettings.load()
        let ws = SavedWorkspace(name: name, slots: slots)
        settings.savedWorkspaces.removeAll { $0.name == name }
        settings.savedWorkspaces.append(ws)
        settings.save()
    }

    /// Restores all applications in a saved workspace back to their exact assigned slots
    public func restoreWorkspace(id: String) {
        let settings = AppSettings.load()
        guard let ws = settings.savedWorkspaces.first(where: { $0.id == id }) else { return }

        for slot in ws.slots {
            let apps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == slot.bundleID && !$0.isTerminated
            }
            guard let app = apps.first else { continue }

            // Target the app's PRIMARY MAIN WINDOW
            guard let (mainWin, _) = try? accessibilityEngine.getMainWindowElement(for: app) else {
                continue
            }

            try? accessibilityEngine.setWindowFrame(slot.frame, element: mainWin)
            app.activate(options: .activateIgnoringOtherApps)
        }
    }

    public func undoLastSnap() {
        let appToSnap = resolveTargetApp()

        do {
            let (element, target) = try accessibilityEngine.getTopmostWindowTarget(preferredApp: appToSnap)
            guard let priorFrame = windowHistory.pop(pid: target.pid) else {
                print("No prior frame found in history for PID \(target.pid)")
                return
            }
            try accessibilityEngine.setWindowFrame(priorFrame, element: element)
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        } catch {
            print("Undo error: \(error.localizedDescription)")
        }
    }
}
