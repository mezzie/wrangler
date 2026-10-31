import AppKit
import Foundation

public struct ScreenInfo: Sendable, Equatable {
    public let id: CGDirectDisplayID
    public let frame: CGRect          // Cocoa coordinates (bottom-left)
    public let visibleFrame: CGRect   // Cocoa coordinates minus Dock/Menu
    public let axFrame: CGRect        // Accessibility coordinates (top-left)
    public let axVisibleFrame: CGRect // Accessibility coordinates minus Dock/Menu

    public init(
        id: CGDirectDisplayID,
        frame: CGRect,
        visibleFrame: CGRect,
        axFrame: CGRect,
        axVisibleFrame: CGRect
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.axFrame = axFrame
        self.axVisibleFrame = axVisibleFrame
    }
}

public final class DisplayManager: @unchecked Sendable {
    public init() {}

    /// Primary screen height needed for Cocoa <-> AX coordinate flips
    public var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    /// Checks if macOS Stage Manager is currently active with persistent side strip
    public static var isStageManagerStripActive: Bool {
        let defaults = UserDefaults(suiteName: "com.apple.WindowManager")
        let enabled = defaults?.bool(forKey: "GloballyEnabled") ?? false
        let autoHide = defaults?.bool(forKey: "AutoHide") ?? false
        return enabled && !autoHide
    }

    /// Converts Cocoa screen rect (bottom-left origin) to AX rect (top-left origin)
    public func cocoaToAX(rect: CGRect) -> CGRect {
        let pHeight = primaryScreenHeight
        let axY = pHeight - (rect.origin.y + rect.height)
        return CGRect(
            x: rect.origin.x,
            y: axY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts AX rect (top-left origin) to Cocoa screen rect (bottom-left origin)
    public func axToCocoa(rect: CGRect) -> CGRect {
        let pHeight = primaryScreenHeight
        let cocoaY = pHeight - (rect.origin.y + rect.height)
        return CGRect(
            x: rect.origin.x,
            y: cocoaY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Adjusts visible frame to avoid Stage Manager thumbnail strip if enabled
    private func applyStageManagerClearance(to visibleFrame: CGRect, screen: NSScreen, settings: AppSettings = .load()) -> CGRect {
        guard settings.avoidStageManager && Self.isStageManagerStripActive else {
            return visibleFrame
        }
        // Only apply to primary or main screen where Stage Manager sits
        guard screen == NSScreen.screens.first else {
            return visibleFrame
        }
        var adjusted = visibleFrame
        let margin = settings.stageManagerMargin
        adjusted.origin.x += margin
        adjusted.size.width = max(100, adjusted.size.width - margin)
        return adjusted
    }

    /// Returns list of all connected displays with precomputed AX frames
    public func getScreens(settings: AppSettings = .load()) -> [ScreenInfo] {
        return NSScreen.screens.compactMap { screen in
            guard let screenIDNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(screenIDNumber.uint32Value)
            let adjustedVisible = applyStageManagerClearance(to: screen.visibleFrame, screen: screen, settings: settings)

            return ScreenInfo(
                id: displayID,
                frame: screen.frame,
                visibleFrame: adjustedVisible,
                axFrame: cocoaToAX(rect: screen.frame),
                axVisibleFrame: cocoaToAX(rect: adjustedVisible)
            )
        }
    }

    /// Finds screen containing mouse cursor, or falls back to main screen
    public func currentScreen(settings: AppSettings = .load()) -> ScreenInfo? {
        let mouseLoc = NSEvent.mouseLocation
        let matched = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? NSScreen.main
        guard let screen = matched,
              let screenIDNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        let displayID = CGDirectDisplayID(screenIDNumber.uint32Value)
        let adjustedVisible = applyStageManagerClearance(to: screen.visibleFrame, screen: screen, settings: settings)

        return ScreenInfo(
            id: displayID,
            frame: screen.frame,
            visibleFrame: adjustedVisible,
            axFrame: cocoaToAX(rect: screen.frame),
            axVisibleFrame: cocoaToAX(rect: adjustedVisible)
        )
    }

    /// Finds screen currently containing a window's center point in AX coordinates
    public func screen(forWindowAXFrame frame: CGRect, settings: AppSettings = .load()) -> ScreenInfo? {
        let screens = getScreens(settings: settings)
        guard !screens.isEmpty else { return nil }

        let windowCenter = CGPoint(x: frame.midX, y: frame.midY)
        // Find screen whose axFrame contains the window center
        if let match = screens.first(where: { $0.axFrame.contains(windowCenter) }) {
            return match
        }
        // Fallback: screen with maximum intersecting area
        var bestScreen = screens[0]
        var maxArea: CGFloat = 0
        for s in screens {
            let intersection = s.axFrame.intersection(frame)
            let area = intersection.width * intersection.height
            if !intersection.isNull && area > maxArea {
                maxArea = area
                bestScreen = s
            }
        }
        return bestScreen
    }

    /// Next display in circular order (Display 1 -> Display 2 -> Display 1)
    public func nextScreen(from current: ScreenInfo, settings: AppSettings = .load()) -> ScreenInfo? {
        let screens = getScreens(settings: settings)
        guard screens.count > 1,
              let currentIndex = screens.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let nextIndex = (currentIndex + 1) % screens.count
        return screens[nextIndex]
    }

    /// Previous display in circular order
    public func previousScreen(from current: ScreenInfo, settings: AppSettings = .load()) -> ScreenInfo? {
        let screens = getScreens(settings: settings)
        guard screens.count > 1,
              let currentIndex = screens.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let prevIndex = (currentIndex - 1 + screens.count) % screens.count
        return screens[prevIndex]
    }

    /// Maps window from source screen to target screen, keeping proportional size/position
    public func mapAXFrame(_ currentFrame: CGRect, from source: ScreenInfo, to target: ScreenInfo) -> CGRect {
        let srcVis = source.axVisibleFrame
        let dstVis = target.axVisibleFrame

        guard srcVis.width > 0, srcVis.height > 0 else {
            return dstVis
        }

        // Relative ratios on source display
        let relX = (currentFrame.origin.x - srcVis.origin.x) / srcVis.width
        let relY = (currentFrame.origin.y - srcVis.origin.y) / srcVis.height
        let relW = currentFrame.width / srcVis.width
        let relH = currentFrame.height / srcVis.height

        // Scaled to target display
        let newW = min(dstVis.width, max(200, relW * dstVis.width))
        let newH = min(dstVis.height, max(150, relH * dstVis.height))
        let newX = dstVis.origin.x + (relX * dstVis.width)
        let newY = dstVis.origin.y + (relY * dstVis.height)

        // Clamp inside target visible frame
        let clampedX = min(max(newX, dstVis.minX), dstVis.maxX - newW)
        let clampedY = min(max(newY, dstVis.minY), dstVis.maxY - newH)

        return CGRect(
            x: round(clampedX),
            y: round(clampedY),
            width: round(newW),
            height: round(newH)
        )
    }
}
