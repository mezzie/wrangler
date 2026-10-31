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
                Task { @MainActor in
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
        guard AccessibilityEngine.isTrusted(promptIfNeeded: true) else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "Wrangler needs Accessibility permission to move windows. Please enable Wrangler in System Settings -> Privacy & Security -> Accessibility."
            alert.alertStyle = .warning
            alert.runModal()
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

        let interactiveView = GridInteractiveView(
            model: selectionModel,
            appName: currentTarget?.appName,
            onUndo: { [weak self] in
                self?.undoLastSnap()
            }
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
        guard let screen = displayManager.currentScreen(),
              let layout = NamedLayout.standardPresets.first(where: { $0.id == preset }) else {
            return
        }

        let appToSnap = resolveTargetApp()

        do {
            let (element, target) = try accessibilityEngine.getWindowTarget(for: appToSnap)
            let targetRectAX = GridMath.calculateRect(
                for: layout.selection,
                in: screen.axVisibleFrame,
                config: layout.config
            )
            windowHistory.push(pid: target.pid, frame: target.frame)
            try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
            NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
        } catch {
            print("Snap preset error: \(error.localizedDescription)")
        }
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
