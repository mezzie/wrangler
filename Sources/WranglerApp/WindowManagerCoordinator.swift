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

    private init() {
        setupSelectionCallbacks()
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
        // Ensure accessibility permissions
        guard AccessibilityEngine.isTrusted(promptIfNeeded: true) else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "Wrangler needs Accessibility permission to move windows. Please enable Wrangler in System Settings -> Privacy & Security -> Accessibility."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        // Grab current frontmost window before HUD takes focus
        do {
            let (element, target) = try accessibilityEngine.getWindowTarget()
            self.currentTargetElement = element
            self.currentTarget = target
        } catch {
            print("Notice: No focused window to snap: \(error.localizedDescription)")
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

        // Restore focus to original application
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

        do {
            let (element, target) = try accessibilityEngine.getWindowTarget()
            let targetRectAX = GridMath.calculateRect(
                for: layout.selection,
                in: screen.axVisibleFrame,
                config: layout.config
            )
            windowHistory.push(pid: target.pid, frame: target.frame)
            try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
        } catch {
            print("Snap preset error: \(error.localizedDescription)")
        }
    }

    public func undoLastSnap() {
        do {
            let (element, target) = try accessibilityEngine.getWindowTarget()
            guard let priorFrame = windowHistory.pop(pid: target.pid) else {
                print("No prior frame found in history for PID \(target.pid)")
                return
            }
            try accessibilityEngine.setWindowFrame(priorFrame, element: element)
        } catch {
            print("Undo error: \(error.localizedDescription)")
        }
    }
}
