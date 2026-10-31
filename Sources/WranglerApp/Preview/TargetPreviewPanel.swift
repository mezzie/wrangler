import AppKit
import SwiftUI

public final class TargetPreviewPanel: NSPanel {
    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hostingView = NSHostingView(rootView: TargetPreviewView())
        self.contentView = hostingView
    }

    public func updateFrame(_ cocoaFrame: CGRect, animated: Bool = true) {
        if !self.isVisible {
            self.setFrame(cocoaFrame, display: true)
            self.orderFront(nil)
        } else {
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.12
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.animator().setFrame(cocoaFrame, display: true)
                }
            } else {
                self.setFrame(cocoaFrame, display: true)
            }
        }
    }

    public func hide() {
        self.orderOut(nil)
    }
}

public struct TargetPreviewView: View {
    public init() {}

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.75), lineWidth: 2)
        }
        .padding(2)
    }
}
