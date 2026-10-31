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

    /// Returns list of all connected displays with precomputed AX frames
    public func getScreens() -> [ScreenInfo] {
        return NSScreen.screens.compactMap { screen in
            guard let screenIDNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(screenIDNumber.uint32Value)
            return ScreenInfo(
                id: displayID,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                axFrame: cocoaToAX(rect: screen.frame),
                axVisibleFrame: cocoaToAX(rect: screen.visibleFrame)
            )
        }
    }

    /// Finds screen containing mouse cursor, or falls back to main screen
    public func currentScreen() -> ScreenInfo? {
        let mouseLoc = NSEvent.mouseLocation
        let matched = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? NSScreen.main
        guard let screen = matched,
              let screenIDNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        let displayID = CGDirectDisplayID(screenIDNumber.uint32Value)
        return ScreenInfo(
            id: displayID,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            axFrame: cocoaToAX(rect: screen.frame),
            axVisibleFrame: cocoaToAX(rect: screen.visibleFrame)
        )
    }
}
