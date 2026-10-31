import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

public struct WindowTarget: Sendable {
    public let pid: pid_t
    public let appName: String?
    public let bundleID: String?
    public let windowTitle: String?
    public let frame: CGRect // in AX coordinates

    public init(
        pid: pid_t,
        appName: String? = nil,
        bundleID: String? = nil,
        windowTitle: String? = nil,
        frame: CGRect
    ) {
        self.pid = pid
        self.appName = appName
        self.bundleID = bundleID
        self.windowTitle = windowTitle
        self.frame = frame
    }
}

public enum AccessibilityError: Error, LocalizedError {
    case permissionDenied
    case noFocusedApplication
    case noFocusedWindow
    case attributeUnavailable(String)
    case setAttributeFailed(AXError)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Accessibility permission not granted. Enable Wrangler in System Settings -> Privacy & Security -> Accessibility."
        case .noFocusedApplication:
            return "No focused frontmost application found."
        case .noFocusedWindow:
            return "No active window found for application."
        case .attributeUnavailable(let attr):
            return "Accessibility attribute '\(attr)' could not be read."
        case .setAttributeFailed(let err):
            return "AXUIElementSetAttributeValue failed with AXError: \(err.rawValue)"
        }
    }
}

public final class AccessibilityEngine: @unchecked Sendable {
    public init() {}

    /// Checks if app has Accessibility privileges
    public static func isTrusted(promptIfNeeded: Bool = false) -> Bool {
        if promptIfNeeded {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    /// Finds the focused or main window element for a specific application
    public func getFocusedWindowElement(for targetApp: NSRunningApplication) throws -> AXUIElement {
        guard Self.isTrusted() else {
            throw AccessibilityError.permissionDenied
        }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)

        // 1. Check focused window
        var focusedVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedVal) == .success,
           let window = focusedVal {
            return (window as! AXUIElement)
        }

        // 2. Check main window (Messages, Safari, Finder often keep main window when focus shifts)
        var mainVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainVal) == .success,
           let window = mainVal {
            return (window as! AXUIElement)
        }

        // 3. Fallback: Find first standard, resizable window in windows list
        var windowsValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
           let windows = windowsValue as? [AXUIElement] {
            for win in windows {
                if let frame = try? getWindowFrame(element: win), frame.width >= 150 && frame.height >= 150 {
                    return win
                }
            }
            if let first = windows.first {
                return first
            }
        }

        throw AccessibilityError.noFocusedWindow
    }

    /// Finds the topmost user window target on screen using Z-order from CoreGraphics
    public func getTopmostWindowTarget(preferredApp: NSRunningApplication? = nil) throws -> (element: AXUIElement, target: WindowTarget) {
        guard Self.isTrusted() else {
            throw AccessibilityError.permissionDenied
        }

        let myPID = ProcessInfo.processInfo.processIdentifier

        // If preferred app given and not self, try it first
        if let app = preferredApp, app.processIdentifier != myPID {
            if let result = try? getWindowTarget(for: app) {
                return result
            }
        }

        // 1. Try system-wide focused application
        let systemWide = AXUIElementCreateSystemWide()
        var focusedAppVal: AnyObject?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppVal) == .success,
           let focusedAppElement = focusedAppVal {
            var pid: pid_t = 0
            AXUIElementGetPid(focusedAppElement as! AXUIElement, &pid)
            if pid != myPID, let app = NSRunningApplication(processIdentifier: pid) {
                if let result = try? getWindowTarget(for: app) {
                    return result
                }
            }
        }

        // 2. Query CoreGraphics for exact Z-order of on-screen windows (top to bottom)
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            throw AccessibilityError.noFocusedWindow
        }

        for info in list {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != myPID,
                  let app = NSRunningApplication(processIdentifier: pid),
                  app.activationPolicy == .regular else {
                continue
            }

            if let result = try? getWindowTarget(for: app) {
                return result
            }
        }

        throw AccessibilityError.noFocusedWindow
    }

    /// Reads window metadata and current frame in AX coordinates for a specific app
    public func getWindowTarget(for app: NSRunningApplication) throws -> (element: AXUIElement, target: WindowTarget) {
        let element = try getFocusedWindowElement(for: app)

        var titleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        let windowTitle = titleValue as? String

        let frame = try getWindowFrame(element: element)

        let target = WindowTarget(
            pid: app.processIdentifier,
            appName: app.localizedName,
            bundleID: app.bundleIdentifier,
            windowTitle: windowTitle,
            frame: frame
        )

        return (element, target)
    }

    /// Convenience to get the current topmost window target
    public func getWindowTarget() throws -> (element: AXUIElement, target: WindowTarget) {
        return try getTopmostWindowTarget()
    }

    /// Reads window position and size (AX coordinates)
    public func getWindowFrame(element: AXUIElement) throws -> CGRect {
        var posValue: AnyObject?
        var sizeValue: AnyObject?

        let posResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue)
        guard posResult == .success, let posVal = posValue else {
            throw AccessibilityError.attributeUnavailable("kAXPositionAttribute")
        }

        let sizeResult = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        guard sizeResult == .success, let sizeVal = sizeValue else {
            throw AccessibilityError.attributeUnavailable("kAXSizeAttribute")
        }

        var point = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(posVal as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)

        return CGRect(origin: point, size: size)
    }

    /// Moves and resizes window to target AX frame using 4-pass constraint resolution
    public func setWindowFrame(_ newFrame: CGRect, element: AXUIElement) throws {
        var point = newFrame.origin
        var size = newFrame.size

        guard let posValue = AXValueCreate(.cgPoint, &point),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return
        }

        // 4-step sequence (Rectangle pattern):
        // Handles both window expanding and window shrinking without hitting screen bounds clamping
        _ = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        _ = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)
        let sizeErr = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        let posErr = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)

        if sizeErr != .success && posErr != .success {
            throw AccessibilityError.setAttributeFailed(sizeErr)
        }
    }

    /// Enumerates all visible, standard application windows currently on a specific screen
    public func getVisibleWindows(on screen: ScreenInfo) -> [(element: AXUIElement, target: WindowTarget)] {
        guard Self.isTrusted() else { return [] }

        var results: [(element: AXUIElement, target: WindowTarget)] = []
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular &&
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier &&
            !$0.isTerminated &&
            !$0.isHidden
        }

        // Put active app first so it gets the master/primary slot
        let sortedApps = apps.sorted { app1, _ in app1.isActive }

        for app in sortedApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowsVal: AnyObject?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
                  let axWindows = windowsVal as? [AXUIElement] else {
                continue
            }

            for winElement in axWindows {
                var minimizedVal: AnyObject?
                if AXUIElementCopyAttributeValue(winElement, kAXMinimizedAttribute as CFString, &minimizedVal) == .success,
                   let isMin = minimizedVal as? Bool, isMin {
                    continue
                }

                guard let frame = try? getWindowFrame(element: winElement),
                      frame.width >= 150, frame.height >= 150 else {
                    continue
                }

                // Check if window intersects screen bounds
                let windowCenter = CGPoint(x: frame.midX, y: frame.midY)
                if screen.axFrame.contains(windowCenter) || screen.axVisibleFrame.intersects(frame) {
                    var titleVal: AnyObject?
                    AXUIElementCopyAttributeValue(winElement, kAXTitleAttribute as CFString, &titleVal)
                    let title = titleVal as? String

                    let target = WindowTarget(
                        pid: app.processIdentifier,
                        appName: app.localizedName,
                        bundleID: app.bundleIdentifier,
                        windowTitle: title,
                        frame: frame
                    )
                    results.append((element: winElement, target: target))
                }
            }
        }

        return results
    }
}
