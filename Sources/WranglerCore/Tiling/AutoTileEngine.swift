import Foundation

public enum AutoTileEngine {
    /// Computes non-overlapping tiled frames for N windows using AeroSpace-style Binary Space Partitioning (BSP)
    public static func calculateFrames(
        count: Int,
        in container: CGRect,
        gap: CGFloat = 8,
        outerMargin: CGFloat = 8
    ) -> [CGRect] {
        guard count > 0 else { return [] }

        let usable = CGRect(
            x: container.origin.x + outerMargin,
            y: container.origin.y + outerMargin,
            width: max(100, container.width - (outerMargin * 2)),
            height: max(100, container.height - (outerMargin * 2))
        )

        if count == 1 {
            return [usable]
        }

        return splitBSP(frame: usable, count: count, depth: 0, gap: gap)
    }

    /// Recursively splits frames alternating vertical (left/right) and horizontal (top/bottom)
    private static func splitBSP(
        frame: CGRect,
        count: Int,
        depth: Int,
        gap: CGFloat
    ) -> [CGRect] {
        if count <= 1 {
            return [frame]
        }

        let isVertical = (depth % 2 == 0) // Even depth: Vertical split. Odd depth: Horizontal split.
        let leftCount = count / 2
        let rightCount = count - leftCount
        let ratio = CGFloat(leftCount) / CGFloat(count)

        if isVertical {
            let usableWidth = max(0, frame.width - gap)
            let leftWidth = round(usableWidth * ratio)
            let rightWidth = usableWidth - leftWidth

            let leftRect = CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: leftWidth,
                height: frame.height
            )
            let rightRect = CGRect(
                x: frame.origin.x + leftWidth + gap,
                y: frame.origin.y,
                width: rightWidth,
                height: frame.height
            )

            return splitBSP(frame: leftRect, count: leftCount, depth: depth + 1, gap: gap) +
                   splitBSP(frame: rightRect, count: rightCount, depth: depth + 1, gap: gap)
        } else {
            let usableHeight = max(0, frame.height - gap)
            let topHeight = round(usableHeight * ratio)
            let bottomHeight = usableHeight - topHeight

            let topRect = CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.width,
                height: topHeight
            )
            let bottomRect = CGRect(
                x: frame.origin.x,
                y: frame.origin.y + topHeight + gap,
                width: frame.width,
                height: bottomHeight
            )

            return splitBSP(frame: topRect, count: leftCount, depth: depth + 1, gap: gap) +
                   splitBSP(frame: bottomRect, count: rightCount, depth: depth + 1, gap: gap)
        }
    }
}
