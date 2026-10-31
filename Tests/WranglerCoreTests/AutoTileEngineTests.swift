import XCTest
@testable import WranglerCore

final class AutoTileEngineTests: XCTestCase {
    let container = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    func testSingleWindowTakesFullArea() {
        let frames = AutoTileEngine.calculateFrames(count: 1, in: container, gap: 10, outerMargin: 20)
        XCTAssertEqual(frames.count, 1)
        XCTAssertEqual(frames[0], CGRect(x: 20, y: 20, width: 1880, height: 1040))
    }

    func testTwoWindowsSplitVertically() {
        let frames = AutoTileEngine.calculateFrames(count: 2, in: container, gap: 10, outerMargin: 0)
        XCTAssertEqual(frames.count, 2)

        // Usable width = 1920 - 10 = 1910. 1910 / 2 = 955 each.
        XCTAssertEqual(frames[0].origin.x, 0)
        XCTAssertEqual(frames[0].width, 955)
        XCTAssertEqual(frames[0].height, 1080)

        XCTAssertEqual(frames[1].origin.x, 965)
        XCTAssertEqual(frames[1].width, 955)
        XCTAssertEqual(frames[1].height, 1080)
    }

    func testThreeWindowsMasterStack() {
        let frames = AutoTileEngine.calculateFrames(count: 3, in: container, gap: 10, outerMargin: 0)
        XCTAssertEqual(frames.count, 3)

        // Left master window
        XCTAssertEqual(frames[0].origin.x, 0)
        XCTAssertEqual(frames[0].origin.y, 0)

        // Right side has two vertically stacked windows (depth 1 horizontal split)
        XCTAssertEqual(frames[1].origin.x, frames[2].origin.x)
        XCTAssertLessThan(frames[1].origin.y, frames[2].origin.y)

        // Verify none overlap
        XCTAssertFalse(frames[0].intersects(frames[1]))
        XCTAssertFalse(frames[0].intersects(frames[2]))
        XCTAssertFalse(frames[1].intersects(frames[2]))
    }

    func testFourWindows2x2Grid() {
        let frames = AutoTileEngine.calculateFrames(count: 4, in: container, gap: 10, outerMargin: 0)
        XCTAssertEqual(frames.count, 4)

        for i in 0..<frames.count {
            for j in (i + 1)..<frames.count {
                XCTAssertFalse(frames[i].intersects(frames[j]), "Frame \(i) and \(j) should not overlap")
            }
        }
    }

    func testManyWindowsNoOverlaps() {
        for count in [5, 6, 8, 10] {
            let frames = AutoTileEngine.calculateFrames(count: count, in: container, gap: 8, outerMargin: 12)
            XCTAssertEqual(frames.count, count)

            for i in 0..<frames.count {
                for j in (i + 1)..<frames.count {
                    XCTAssertFalse(frames[i].intersects(frames[j]), "Overlapping frames for count \(count)")
                }
            }
        }
    }
}
