import XCTest
@testable import WranglerCore

final class GridMathTests: XCTestCase {
    func testSingleCellCalculation() {
        let container = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let config = GridConfig(columns: 2, rows: 2, gap: 0, outerMargin: 0)
        let selection = GridSelection(single: GridCellIndex(col: 0, row: 0))

        let rect = GridMath.calculateRect(for: selection, in: container, config: config)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 500, height: 500))
    }

    func testLeftHalfPreset() {
        let container = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let config = GridConfig(columns: 4, rows: 4, gap: 0, outerMargin: 0)
        let selection = GridSelection(
            start: GridCellIndex(col: 0, row: 0),
            end: GridCellIndex(col: 1, row: 3)
        )

        let rect = GridMath.calculateRect(for: selection, in: container, config: config)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 500, height: 800))
    }

    func testRightHalfPreset() {
        let container = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let config = GridConfig(columns: 4, rows: 4, gap: 0, outerMargin: 0)
        let selection = GridSelection(
            start: GridCellIndex(col: 2, row: 0),
            end: GridCellIndex(col: 3, row: 3)
        )

        let rect = GridMath.calculateRect(for: selection, in: container, config: config)
        XCTAssertEqual(rect, CGRect(x: 500, y: 0, width: 500, height: 800))
    }

    func testMarginsAndGaps() {
        let container = CGRect(x: 100, y: 100, width: 1000, height: 1000)
        let config = GridConfig(columns: 2, rows: 2, gap: 10, outerMargin: 20)
        // Usable = 1000 - 40 = 960
        // Cells width = (960 - 10) / 2 = 475 each
        let topLeft = GridSelection(single: GridCellIndex(col: 0, row: 0))
        let rectTopLeft = GridMath.calculateRect(for: topLeft, in: container, config: config)
        XCTAssertEqual(rectTopLeft.origin.x, 120)
        XCTAssertEqual(rectTopLeft.origin.y, 120)
        XCTAssertEqual(rectTopLeft.width, 475)
        XCTAssertEqual(rectTopLeft.height, 475)

        // Spanning all 4 cells (0,0 to 1,1)
        let fullSpan = GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 1, row: 1))
        let rectFull = GridMath.calculateRect(for: fullSpan, in: container, config: config)
        XCTAssertEqual(rectFull.origin.x, 120)
        XCTAssertEqual(rectFull.origin.y, 120)
        XCTAssertEqual(rectFull.width, 960)
        XCTAssertEqual(rectFull.height, 960)
    }

    func testInvertedSelectionHandlesCorrectly() {
        // Dragging bottom-right to top-left
        let selection = GridSelection(
            start: GridCellIndex(col: 3, row: 3),
            end: GridCellIndex(col: 0, row: 0)
        )
        XCTAssertEqual(selection.minCol, 0)
        XCTAssertEqual(selection.maxCol, 3)
        XCTAssertEqual(selection.minRow, 0)
        XCTAssertEqual(selection.maxRow, 3)
        XCTAssertEqual(selection.colSpan, 4)
        XCTAssertEqual(selection.rowSpan, 4)
    }
}
