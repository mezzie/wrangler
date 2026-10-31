import AppKit
import SwiftUI
import WranglerCore

public final class GridCanvasView: NSView {
    public var model: GridSelectionModel? {
        didSet {
            needsDisplay = true
        }
    }

    public override var isFlipped: Bool { true }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    private func cellIndex(at point: CGPoint) -> (col: Int, row: Int)? {
        guard let model = model else { return nil }
        let cols = CGFloat(model.config.columns)
        let rows = CGFloat(model.config.rows)
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let cellW = bounds.width / cols
        let cellH = bounds.height / rows

        let col = max(0, min(model.config.columns - 1, Int(point.x / cellW)))
        let row = max(0, min(model.config.rows - 1, Int(point.y / cellH)))

        return (col, row)
    }

    public override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        guard let (col, row) = cellIndex(at: loc) else { return }
        model?.dragBegan(col: col, row: row)
        needsDisplay = true
    }

    public override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        guard let (col, row) = cellIndex(at: loc) else { return }
        model?.cellHovered(col: col, row: row)
        needsDisplay = true
    }

    public override func mouseUp(with event: NSEvent) {
        model?.dragEnded()
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let model = model else { return }

        let cols = model.config.columns
        let rows = model.config.rows
        let gap: CGFloat = 4

        let totalGapsX = gap * CGFloat(cols - 1)
        let totalGapsY = gap * CGFloat(rows - 1)

        let cellW = max(4, (bounds.width - totalGapsX) / CGFloat(cols))
        let cellH = max(4, (bounds.height - totalGapsY) / CGFloat(rows))

        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * (cellW + gap)
                let y = CGFloat(r) * (cellH + gap)
                let cellRect = NSRect(x: x, y: y, width: cellW, height: cellH)

                let path = NSBezierPath(roundedRect: cellRect, xRadius: 6, yRadius: 6)

                let isSelected = model.isCellSelected(col: c, row: r)

                if isSelected {
                    NSColor.controlAccentColor.setFill()
                    path.fill()

                    NSColor.white.withAlphaComponent(0.45).setStroke()
                    path.lineWidth = 1.5
                    path.stroke()
                } else {
                    NSColor.labelColor.withAlphaComponent(0.08).setFill()
                    path.fill()

                    NSColor.labelColor.withAlphaComponent(0.12).setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }
            }
        }
    }
}

public struct GridCanvasRepresentable: NSViewRepresentable {
    @ObservedObject public var model: GridSelectionModel

    public init(model: GridSelectionModel) {
        self.model = model
    }

    public func makeNSView(context: Context) -> GridCanvasView {
        let view = GridCanvasView(frame: .zero)
        view.model = model
        return view
    }

    public func updateNSView(_ nsView: GridCanvasView, context: Context) {
        nsView.model = model
        nsView.needsDisplay = true
    }
}
