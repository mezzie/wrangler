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

    public func updateFrame(_ cocoaFrame: CGRect) {
        self.setFrame(cocoaFrame, display: true)
        if !self.isVisible {
            self.orderFront(nil)
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
