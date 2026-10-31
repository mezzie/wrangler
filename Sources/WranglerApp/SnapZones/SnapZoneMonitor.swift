import AppKit
import WranglerCore

@MainActor
public final class SnapZoneMonitor {
    public static let shared = SnapZoneMonitor()

    private var eventMonitor: Any?
    private var moveMonitor: Any?
    private let accessibilityEngine = AccessibilityEngine()
    private let displayManager = DisplayManager()
    private let windowHistory = WindowHistory()
    private let previewPanel = TargetPreviewPanel()

    private var activeTargetRectAX: CGRect?

    // Shake detection state
    private var shakeDeltas: [CGFloat] = []
    private var lastShakeTime: Date = Date()
    private var lastMouseX: CGFloat = 0

    private init() {}

    public func start() {
        stop()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleMouseEvent(event)
            }
        }

        // Mouse moved monitor for shake-to-summon
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleMouseMoved(event)
            }
        }
    }

    public func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = moveMonitor {
            NSEvent.removeMonitor(monitor)
            moveMonitor = nil
        }
        previewPanel.hide()
        activeTargetRectAX = nil
    }

    private func handleMouseMoved(_ event: NSEvent) {
        let settings = AppSettings.load()
        guard settings.shakeToSummon else { return }

        let currentX = NSEvent.mouseLocation.x
        let now = Date()
        let dt = now.timeIntervalSince(lastShakeTime)

        if dt > 0.4 {
            shakeDeltas.removeAll()
        }
        lastShakeTime = now

        let dx = currentX - lastMouseX
        lastMouseX = currentX

        // Only record significant movements
        if abs(dx) > 15 {
            shakeDeltas.append(dx)
            if shakeDeltas.count > 10 {
                shakeDeltas.removeFirst()
            }

            // Check for at least 4 alternating direction reversals
            var reversals = 0
            for i in 1..<shakeDeltas.count {
                if (shakeDeltas[i] > 0 && shakeDeltas[i - 1] < 0) || (shakeDeltas[i] < 0 && shakeDeltas[i - 1] > 0) {
                    reversals += 1
                }
            }

            if reversals >= 4 {
                shakeDeltas.removeAll()
                WindowManagerCoordinator.shared.showOverlay()
            }
        }
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

            var matched: CGRect?

            // 1. Check modifier-hold snap (holding Control or fn reveals zone under cursor anywhere)
            let flags = event.modifierFlags
            if settings.modifierHoldSnap && (flags.contains(.control) || flags.contains(.function)) {
                let vis = screen.visibleFrame
                let relX = (mouseLoc.x - vis.minX) / vis.width
                switch settings.snapZoneTemplate {
                case .twoColumns:
                    let side: SnapZoneEngine.Side = relX < 0.5 ? .left : .right
                    matched = SnapZoneEngine.calculateTemplateTile(side: side, template: .twoColumns, in: screen.axVisibleFrame, gap: settings.gap, outerMargin: settings.outerMargin)
                case .threeColumns:
                    let side: SnapZoneEngine.Side = relX < 0.33 ? .left : (relX < 0.66 ? .center : .right)
                    matched = SnapZoneEngine.calculateTemplateTile(side: side, template: .threeColumns, in: screen.axVisibleFrame, gap: settings.gap, outerMargin: settings.outerMargin)
                case .ultrawideFocus:
                    let side: SnapZoneEngine.Side = relX < 0.25 ? .left : (relX < 0.75 ? .center : .right)
                    matched = SnapZoneEngine.calculateTemplateTile(side: side, template: .ultrawideFocus, in: screen.axVisibleFrame, gap: settings.gap, outerMargin: settings.outerMargin)
                }
            } else {
                // 2. Standard edge-drag detection
                matched = SnapZoneEngine.matchZone(
                    mousePoint: mouseLoc,
                    screen: screen,
                    template: settings.snapZoneTemplate,
                    gap: settings.gap,
                    outerMargin: settings.outerMargin,
                    threshold: settings.snapTriggerThreshold
                )
            }

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
