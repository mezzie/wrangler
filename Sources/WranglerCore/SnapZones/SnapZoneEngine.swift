import Foundation
import CoreGraphics

public enum SnapZoneEngine {
    /// Detects if mouse cursor is inside an edge trigger zone and returns target AX frame
    public static func matchZone(
        mousePoint: CGPoint, // in Cocoa coordinates
        screen: ScreenInfo,
        template: SnapZoneTemplate,
        gap: CGFloat = 8,
        outerMargin: CGFloat = 8,
        threshold: CGFloat = 25
    ) -> CGRect? {
        let vis = screen.visibleFrame
        guard vis.contains(mousePoint) || screen.frame.contains(mousePoint) else {
            return nil
        }

        let isAtLeftEdge = mousePoint.x <= (vis.minX + threshold)
        let isAtRightEdge = mousePoint.x >= (vis.maxX - threshold)
        let isAtTopEdge = mousePoint.y >= (vis.maxY - threshold)
        let isAtBottomEdge = mousePoint.y <= (vis.minY + threshold)

        // Must be touching at least one edge trigger
        guard isAtLeftEdge || isAtRightEdge || isAtTopEdge || isAtBottomEdge else {
            return nil
        }

        // 1. Top Corners (Quarters)
        if isAtTopEdge && isAtLeftEdge {
            return calculateQuarter(corner: .topLeft, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }
        if isAtTopEdge && isAtRightEdge {
            return calculateQuarter(corner: .topRight, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }

        // 2. Bottom Corners (Quarters)
        if isAtBottomEdge && isAtLeftEdge {
            return calculateQuarter(corner: .bottomLeft, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }
        if isAtBottomEdge && isAtRightEdge {
            return calculateQuarter(corner: .bottomRight, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }

        // 3. Top Edge (Maximize)
        if isAtTopEdge && !isAtLeftEdge && !isAtRightEdge {
            return calculateMaximize(in: screen.axVisibleFrame, outerMargin: outerMargin)
        }

        // 4. Left Edge -> Left Template Tile
        if isAtLeftEdge {
            return calculateTemplateTile(side: .left, template: template, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }

        // 5. Right Edge -> Right Template Tile
        if isAtRightEdge {
            return calculateTemplateTile(side: .right, template: template, in: screen.axVisibleFrame, gap: gap, outerMargin: outerMargin)
        }

        return nil
    }

    public enum Side {
        case left
        case center
        case right
    }

    public enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    private static func calculateMaximize(in container: CGRect, outerMargin: CGFloat) -> CGRect {
        CGRect(
            x: container.origin.x + outerMargin,
            y: container.origin.y + outerMargin,
            width: max(100, container.width - (outerMargin * 2)),
            height: max(100, container.height - (outerMargin * 2))
        )
    }

    private static func calculateQuarter(corner: Corner, in container: CGRect, gap: CGFloat, outerMargin: CGFloat) -> CGRect {
        let usableW = container.width - (outerMargin * 2) - gap
        let usableH = container.height - (outerMargin * 2) - gap
        let w = round(usableW / 2)
        let h = round(usableH / 2)

        let startX = container.origin.x + outerMargin
        let startY = container.origin.y + outerMargin

        switch corner {
        case .topLeft:
            return CGRect(x: startX, y: startY, width: w, height: h)
        case .topRight:
            return CGRect(x: startX + w + gap, y: startY, width: w, height: h)
        case .bottomLeft:
            return CGRect(x: startX, y: startY + h + gap, width: w, height: h)
        case .bottomRight:
            return CGRect(x: startX + w + gap, y: startY + h + gap, width: w, height: h)
        }
    }

    public static func calculateTemplateTile(
        side: Side,
        template: SnapZoneTemplate,
        in container: CGRect,
        gap: CGFloat,
        outerMargin: CGFloat
    ) -> CGRect {
        let usableW = container.width - (outerMargin * 2)
        let usableH = container.height - (outerMargin * 2)
        let startX = container.origin.x + outerMargin
        let startY = container.origin.y + outerMargin

        switch template {
        case .twoColumns:
            // 50% / 50%
            let colW = round((usableW - gap) / 2)
            if side == .left {
                return CGRect(x: startX, y: startY, width: colW, height: usableH)
            } else {
                return CGRect(x: startX + colW + gap, y: startY, width: colW, height: usableH)
            }

        case .threeColumns:
            // 33% / 33% / 33%
            let colW = round((usableW - (gap * 2)) / 3)
            switch side {
            case .left:
                return CGRect(x: startX, y: startY, width: colW, height: usableH)
            case .center:
                return CGRect(x: startX + colW + gap, y: startY, width: colW, height: usableH)
            case .right:
                return CGRect(x: startX + (colW * 2) + (gap * 2), y: startY, width: colW, height: usableH)
            }

        case .ultrawideFocus:
            // 25% | 50% | 25%
            let sideW = round((usableW - (gap * 2)) * 0.25)
            let centerW = usableW - (sideW * 2) - (gap * 2)
            switch side {
            case .left:
                return CGRect(x: startX, y: startY, width: sideW, height: usableH)
            case .center:
                return CGRect(x: startX + sideW + gap, y: startY, width: centerW, height: usableH)
            case .right:
                return CGRect(x: startX + sideW + centerW + (gap * 2), y: startY, width: sideW, height: usableH)
            }
        }
    }
}
