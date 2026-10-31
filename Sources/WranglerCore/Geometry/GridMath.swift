import Foundation

/// Defines grid layout dimensions and spacing rules
public struct GridConfig: Codable, Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let gap: CGFloat
    public let outerMargin: CGFloat

    public init(columns: Int = 4, rows: Int = 4, gap: CGFloat = 8, outerMargin: CGFloat = 8) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.gap = max(0, gap)
        self.outerMargin = max(0, outerMargin)
    }

    public static let default4x4 = GridConfig(columns: 4, rows: 4, gap: 8, outerMargin: 8)
    public static let halves = GridConfig(columns: 2, rows: 1, gap: 8, outerMargin: 8)
    public static let thirds = GridConfig(columns: 3, rows: 1, gap: 8, outerMargin: 8)
}

/// Zero-indexed coordinate in the grid (0,0 is top-left cell)
public struct GridCellIndex: Hashable, Codable, Equatable, Sendable {
    public let col: Int
    public let row: Int

    public init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }
}

/// Represents selection spanning from one cell to another (drag box)
public struct GridSelection: Codable, Equatable, Sendable {
    public let start: GridCellIndex
    public let end: GridCellIndex

    public init(start: GridCellIndex, end: GridCellIndex) {
        self.start = start
        self.end = end
    }

    public init(single cell: GridCellIndex) {
        self.start = cell
        self.end = cell
    }

    public var minCol: Int { min(start.col, end.col) }
    public var maxCol: Int { max(start.col, end.col) }
    public var minRow: Int { min(start.row, end.row) }
    public var maxRow: Int { max(start.row, end.row) }

    public var colSpan: Int { maxCol - minCol + 1 }
    public var rowSpan: Int { maxRow - minRow + 1 }
}

public enum GridMath {
    /// Computes target pixel rect within a container (e.g. screen visibleFrame)
    /// containerRect coordinates are assumed top-left relative or pure dimensions
    public static func calculateRect(
        for selection: GridSelection,
        in containerRect: CGRect,
        config: GridConfig
    ) -> CGRect {
        let cols = CGFloat(config.columns)
        let rows = CGFloat(config.rows)

        // Available area after subtracting outer margins
        let usableWidth = containerRect.width - (config.outerMargin * 2)
        let usableHeight = containerRect.height - (config.outerMargin * 2)

        guard usableWidth > 0, usableHeight > 0 else {
            return containerRect
        }

        // Available space for cells after subtracting inner gaps
        let totalHorizontalGaps = config.gap * max(0, cols - 1)
        let totalVerticalGaps = config.gap * max(0, rows - 1)

        let cellWidth = max(1, (usableWidth - totalHorizontalGaps) / cols)
        let cellHeight = max(1, (usableHeight - totalVerticalGaps) / rows)

        let minCol = CGFloat(max(0, min(selection.minCol, config.columns - 1)))
        let minRow = CGFloat(max(0, min(selection.minRow, config.rows - 1)))
        let colSpan = CGFloat(min(selection.colSpan, config.columns - Int(minCol)))
        let rowSpan = CGFloat(min(selection.rowSpan, config.rows - Int(minRow)))

        let xOffset = containerRect.origin.x + config.outerMargin + (minCol * (cellWidth + config.gap))
        let yOffset = containerRect.origin.y + config.outerMargin + (minRow * (cellHeight + config.gap))

        let width = (colSpan * cellWidth) + (max(0, colSpan - 1) * config.gap)
        let height = (rowSpan * cellHeight) + (max(0, rowSpan - 1) * config.gap)

        return CGRect(
            x: round(xOffset),
            y: round(yOffset),
            width: round(width),
            height: round(height)
        )
    }
}
