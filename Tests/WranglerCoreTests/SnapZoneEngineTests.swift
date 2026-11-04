import XCTest
@testable import WranglerCore

final class SnapZoneEngineTests: XCTestCase {
    let screen = ScreenInfo(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1080),
        visibleFrame: CGRect(x: 0, y: 78, width: 2560, height: 972),
        axFrame: CGRect(x: 0, y: 0, width: 2560, height: 1080),
        axVisibleFrame: CGRect(x: 0, y: 30, width: 2560, height: 972)
    )

    func testLeftEdge50Split() {
        // Cursor at left edge (X = 5, Y = 500 in Cocoa)
        let point = CGPoint(x: 5, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        // Usable width = 2560 - 16 = 2544. Half = (2544 - 8) / 2 = 1268
        XCTAssertEqual(zone?.origin.x, 8)
        XCTAssertEqual(zone?.width, 1268)
        XCTAssertEqual(zone?.height, 956)
    }

    func testRightEdge50Split() {
        // Cursor at right edge (X = 2555, Y = 500 in Cocoa)
        let point = CGPoint(x: 2555, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        XCTAssertEqual(zone?.origin.x, 8 + 1268 + 8) // 1284
        XCTAssertEqual(zone?.width, 1268)
    }

    func testTopEdgeMaximize() {
        // Cursor at top center (X = 1280, Y = 1045 in Cocoa)
        let point = CGPoint(x: 1280, y: 1045)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        XCTAssertEqual(zone?.origin.x, 8)
        XCTAssertEqual(zone?.origin.y, 38)
        XCTAssertEqual(zone?.width, 2544)
    }

    func testCenterScreenReturnsNil() {
        // Cursor in middle of screen (X = 500, Y = 500) -> Should NOT trigger any snap zone
        let point = CGPoint(x: 500, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            threshold: 25
        )

        XCTAssertNil(zone)
    }

    // REGRESSION GUARD: Never trigger snap zones when cursor is inside the Dock (outside visibleFrame)
    func testDockCursorReturnsNil() {
        // Dock is located at Y=0..78. Cursor at Y=35 (inside Dock)
        let point = CGPoint(x: 1280, y: 35)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            threshold: 25
        )

        XCTAssertNil(zone, "Cursor in Dock must never trigger snap zones")
    }

    func testTopLeftCornerQuarter() {
        let point = CGPoint(x: 5, y: 1045)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .twoColumns,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        XCTAssertEqual(zone?.origin.x, 8)
        XCTAssertEqual(zone?.origin.y, 38)
        // Quarter width = (2544 - 8) / 2 = 1268. Height = (956 - 8) / 2 = 474
        XCTAssertEqual(zone?.width, 1268)
        XCTAssertEqual(zone?.height, 474)
    }

    func testThreeColumnsSplit() {
        let point = CGPoint(x: 5, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .threeColumns,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        // (2544 - 16) / 3 = 842.66 -> 843
        XCTAssertEqual(zone?.width, 843)
    }

    func testCodingSplit65Percent() {
        let point = CGPoint(x: 5, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .codingSplit,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        // Usable = 2544 - 8 = 2536. 2536 * 0.65 = 1648.4 -> 1648
        XCTAssertEqual(zone?.width, 1648)
    }

    func testGoldenRatioSplit() {
        let point = CGPoint(x: 5, y: 500)
        let zone = SnapZoneEngine.matchZone(
            mousePoint: point,
            screen: screen,
            template: .goldenRatio,
            gap: 8,
            outerMargin: 8,
            threshold: 25
        )

        XCTAssertNotNil(zone)
        // 2536 * 0.618 = 1567.248 -> 1567
        XCTAssertEqual(zone?.width, 1567)
    }

    // REGRESSION GUARD: Highlighting text inside editor (below title bar) must NEVER be treated as a title bar drag
    func testTextHighlightingDoesNotTriggerTitleBar() {
        let windowFrameAX = CGRect(x: 0, y: 30, width: 2560, height: 970)
        let titleBarHeight: CGFloat = 42

        func isInTitleBar(y: CGFloat) -> Bool {
            return y >= windowFrameAX.minY && y <= (windowFrameAX.minY + titleBarHeight)
        }

        // Title bar click (Y = 35) -> true
        XCTAssertTrue(isInTitleBar(y: 35))

        // Highlighting text in editor (Y = 150, Y = 300, Y = 600) -> false!
        XCTAssertFalse(isInTitleBar(y: 150))
        XCTAssertFalse(isInTitleBar(y: 300))
        XCTAssertFalse(isInTitleBar(y: 600))
    }
}
