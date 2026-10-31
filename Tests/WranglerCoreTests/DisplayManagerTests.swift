import XCTest
@testable import WranglerCore

final class DisplayManagerTests: XCTestCase {
    func testMapAXFrameBetweenDisplays() {
        let displays = DisplayManager()

        let screen1 = ScreenInfo(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
            axFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            axVisibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055)
        )

        let screen2 = ScreenInfo(
            id: 2,
            frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 1920, y: 0, width: 2560, height: 1415),
            axFrame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            axVisibleFrame: CGRect(x: 1920, y: 25, width: 2560, height: 1415)
        )

        // Window on screen 1 occupying left half
        let winFrame = CGRect(x: 0, y: 25, width: 960, height: 1055)

        let mapped = displays.mapAXFrame(winFrame, from: screen1, to: screen2)

        XCTAssertEqual(mapped.origin.x, 1920)
        XCTAssertEqual(mapped.origin.y, 25)
        XCTAssertEqual(mapped.width, 1280) // 2560 / 2
        XCTAssertEqual(mapped.height, 1415)
    }

    func testNextCycledPreset() {
        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "left-half"), "left-two-thirds")
        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "left-two-thirds"), "left-one-third")
        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "left-one-third"), "left-half")

        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "right-half"), "right-two-thirds")
        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "right-two-thirds"), "right-one-third")
        XCTAssertEqual(NamedLayout.nextCycledPreset(for: "right-one-third"), "right-half")
    }
}
