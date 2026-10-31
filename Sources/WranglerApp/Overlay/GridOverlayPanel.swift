import AppKit
import SwiftUI
import WranglerCore

public final class GridOverlayPanel: NSPanel {
    private var localEventMonitor: Any?

    public init(rootView: AnyView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 290, height: 260),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hostingView = NSHostingView(rootView: rootView)
        self.contentView = hostingView
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public func show(on screen: ScreenInfo, at mouseLocation: CGPoint? = nil) {
        let size = self.frame.size
        let targetPoint: CGPoint

        if let mouseLoc = mouseLocation {
            // Position near cursor, ensuring panel stays within screen visible frame
            let x = min(max(mouseLoc.x - size.width / 2, screen.visibleFrame.minX), screen.visibleFrame.maxX - size.width)
            let y = min(max(mouseLoc.y - size.height / 2, screen.visibleFrame.minY), screen.visibleFrame.maxY - size.height)
            targetPoint = CGPoint(x: x, y: y)
        } else {
            // Center of screen
            let x = screen.visibleFrame.midX - (size.width / 2)
            let y = screen.visibleFrame.midY - (size.height / 2)
            targetPoint = CGPoint(x: x, y: y)
        }

        self.setFrameOrigin(targetPoint)
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        setupDismissMonitors()
    }

    public func hide() {
        tearDownDismissMonitors()
        self.orderOut(nil)
    }

    private func setupDismissMonitors() {
        tearDownDismissMonitors()
        // Listen for ESC key
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.hide()
                return nil
            }
            return event
        }
    }

    private func tearDownDismissMonitors() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    public override func cancelOperation(_ sender: Any?) {
        hide()
    }
}
