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

    // Window drag tracking
    private var trackedWindow: AXUIElement?
    private var initialWindowOrigin: CGPoint?
    private var isTitleBarDrag: Bool = false

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
        trackedWindow = nil
        initialWindowOrigin = nil
        isTitleBarDrag = false
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

        if abs(dx) > 15 {
            shakeDeltas.append(dx)
            if shakeDeltas.count > 10 {
                shakeDeltas.removeFirst()
            }

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

    private func isPointInTitleBar(mouseLocAX: CGPoint, windowFrameAX: CGRect) -> Bool {
        let titleBarHeight: CGFloat = 42
        return mouseLocAX.x >= windowFrameAX.minX &&
               mouseLocAX.x <= windowFrameAX.maxX &&
               mouseLocAX.y >= windowFrameAX.minY &&
               mouseLocAX.y <= (windowFrameAX.minY + titleBarHeight)
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

            // 1. Never trigger if cursor is in Dock or Menu Bar (outside visibleFrame)
            guard screen.visibleFrame.contains(mouseLoc) else {
                if activeTargetRectAX != nil {
                    previewPanel.hide()
                    activeTargetRectAX = nil
                }
                return
            }

            // 2. Never trigger if frontmost application is Dock or SystemUIServer
            if let front = NSWorkspace.shared.frontmostApplication,
               front.bundleIdentifier == "com.apple.dock" || front.bundleIdentifier == "com.apple.systemuiserver" {
                return
            }

            // 3. Initialize drag tracking on first dragged event
            if initialWindowOrigin == nil {
                if let (win, target) = try? accessibilityEngine.getTopmostWindowTarget() {
                    let mouseLocAX = displayManager.cocoaToAX(rect: CGRect(origin: mouseLoc, size: .zero)).origin

                    // Verify the drag started on the window's title bar (not inside text area, editor, or web canvas)
                    if isPointInTitleBar(mouseLocAX: mouseLocAX, windowFrameAX: target.frame) {
                        trackedWindow = win
                        initialWindowOrigin = target.frame.origin
                        isTitleBarDrag = true
                    } else {
                        isTitleBarDrag = false
                        return
                    }
                } else {
                    return
                }
            }

            // 4. Must be a title bar drag and window MUST physically move >= 20px
            guard isTitleBarDrag,
                  let win = trackedWindow,
                  let origin = initialWindowOrigin else {
                return
            }

            guard let currentFrame = try? accessibilityEngine.getWindowFrame(element: win) else {
                return
            }

            let dist = hypot(currentFrame.origin.x - origin.x, currentFrame.origin.y - origin.y)
            guard dist >= 20 else {
                // Window hasn't moved yet (text selection, clicking inside window)
                return
            }

            var matched: CGRect?

            // 5. Check modifier-hold snap or edge-drag
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
                case .codingSplit:
                    let side: SnapZoneEngine.Side = relX < 0.65 ? .left : .right
                    matched = SnapZoneEngine.calculateTemplateTile(side: side, template: .codingSplit, in: screen.axVisibleFrame, gap: settings.gap, outerMargin: settings.outerMargin)
                case .goldenRatio:
                    let side: SnapZoneEngine.Side = relX < 0.618 ? .left : .right
                    matched = SnapZoneEngine.calculateTemplateTile(side: side, template: .goldenRatio, in: screen.axVisibleFrame, gap: settings.gap, outerMargin: settings.outerMargin)
                }
            } else {
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
            let wasActive = (activeTargetRectAX != nil)
            let targetRectAX = activeTargetRectAX

            // Reset drag tracking state
            trackedWindow = nil
            initialWindowOrigin = nil
            isTitleBarDrag = false
            previewPanel.hide()
            activeTargetRectAX = nil

            guard wasActive, let snapRect = targetRectAX else { return }

            // Snap the window that was dragged by title bar
            do {
                let (element, target) = try accessibilityEngine.getTopmostWindowTarget()
                windowHistory.push(pid: target.pid, frame: target.frame)
                try accessibilityEngine.setWindowFrame(snapRect, element: element)
                NSRunningApplication(processIdentifier: target.pid)?.activate(options: .activateIgnoringOtherApps)
            } catch {
                print("Snap Zone drop error: \(error.localizedDescription)")
            }

        default:
            break
        }
    }
}
