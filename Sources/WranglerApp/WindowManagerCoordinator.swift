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
            Task { @MainActor in
                self?.handleSelectionChanged(selection)
            }
        }

        selectionModel.onSelectionCommitted = { [weak self] selection in
            Task { @MainActor in
                self?.handleSelectionCommitted(selection)
            }
        }

        selectionModel.onCancel = { [weak self] in
            Task { @MainActor in
                self?.dismissOverlay()
            }
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

        // Capture target window before HUD display
        do {
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
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
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
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
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
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
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
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

        dismissOverlay()
    }

    public func undoLastSnap() {
        let appToSnap = resolveTargetApp()

        do {
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
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
