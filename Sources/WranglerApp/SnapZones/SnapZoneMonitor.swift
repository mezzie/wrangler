import AppKit
import WranglerCore

@MainActor
public final class SnapZoneMonitor {
    public static let shared = SnapZoneMonitor()

    private var eventMonitor: Any?
    private let accessibilityEngine = AccessibilityEngine()
    private let displayManager = DisplayManager()
    private let windowHistory = WindowHistory()
    private let previewPanel = TargetPreviewPanel()

    private var activeTargetRectAX: CGRect?

    private init() {}

    public func start() {
        stop()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleMouseEvent(event)
            }
        }
    }

    public func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        previewPanel.hide()
        activeTargetRectAX = nil
    }

    private func handleMouseEvent(_ event: NSEvent) {
        let settings = AppSettings.load()
        guard settings.enableSnapZones else {
            if activeTargetRectAX != nil {
                previewPanel.hide()
                activeTargetRectAX = nil
            }
            return
        }

        switch event.type {
        case .leftMouseDragged:
            guard let screen = displayManager.currentScreen() else { return }
            let mouseLoc = NSEvent.mouseLocation

            let matched = SnapZoneEngine.matchZone(
                mousePoint: mouseLoc,
                screen: screen,
                template: settings.snapZoneTemplate,
                gap: settings.gap,
                outerMargin: settings.outerMargin,
                threshold: settings.snapTriggerThreshold
            )

            if let zoneAX = matched {
                activeTargetRectAX = zoneAX
                let cocoaRect = displayManager.axToCocoa(rect: zoneAX)
                previewPanel.updateFrame(cocoaRect)
            } else if activeTargetRectAX != nil {
                previewPanel.hide()
                activeTargetRectAX = nil
            }

        case .leftMouseUp:
            guard let targetRectAX = activeTargetRectAX else { return }
            previewPanel.hide()
            activeTargetRectAX = nil

            // Snap the window that was just dropped
            do {
                let (element, target) = try accessibilityEngine.getTopmostWindowTarget()
                windowHistory.push(pid: target.pid, frame: target.frame)
                try accessibilityEngine.setWindowFrame(targetRectAX, element: element)
                NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
            } catch {
                print("Snap Zone drop error: \(error.localizedDescription)")
            }

        default:
            break
        }
    }
}
