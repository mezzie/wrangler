import AppKit
import ApplicationServices
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

    /// Retrieves frontmost focused AXUIElement window
    public func getFocusedWindowElement() throws -> AXUIElement {
        guard Self.isTrusted() else {
            throw AccessibilityError.permissionDenied
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw AccessibilityError.noFocusedApplication
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue)

        guard result == .success, let window = windowValue else {
            throw AccessibilityError.noFocusedWindow
        }

        return (window as! AXUIElement)
    }

    /// Reads window metadata and current frame in AX coordinates
    public func getWindowTarget(for windowElement: AXUIElement? = nil) throws -> (element: AXUIElement, target: WindowTarget) {
        let element = try (windowElement ?? getFocusedWindowElement())

        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)

        let runningApp = NSRunningApplication(processIdentifier: pid)
        let appName = runningApp?.localizedName
        let bundleID = runningApp?.bundleIdentifier

        var titleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        let windowTitle = titleValue as? String

        let frame = try getWindowFrame(element: element)

        let target = WindowTarget(
            pid: pid,
            appName: appName,
            bundleID: bundleID,
            windowTitle: windowTitle,
            frame: frame
        )

        return (element, target)
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

    /// Moves and resizes window to target AX frame
    public func setWindowFrame(_ newFrame: CGRect, element: AXUIElement) throws {
        var point = newFrame.origin
        var size = newFrame.size

        guard let posValue = AXValueCreate(.cgPoint, &point),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return
        }

        // Standard window manager pattern:
        // Set position -> Set size -> Set position again to accommodate macOS size constraints
        _ = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)
        let sizeErr = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        let posErr = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)

        if sizeErr != .success && posErr != .success {
            throw AccessibilityError.setAttributeFailed(sizeErr)
        }
    }
}
