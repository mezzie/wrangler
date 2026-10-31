import XCTest
@testable import WranglerCore

final class CustomShortcutTests: XCTestCase {
    func testDefaultShortcuts() {
        XCTAssertEqual(CustomShortcut.defaultOverlay.displayString, "⌥ Space")
        XCTAssertEqual(CustomShortcut.defaultMaximize.displayString, "⌃ ⌥ ↵")
        XCTAssertEqual(CustomShortcut.defaultAutoTile.displayString, "⌃ ⌥ T")
        XCTAssertEqual(CustomShortcut.defaultNextDisplay.displayString, "⌃ ⌥ →")
        XCTAssertEqual(CustomShortcut.defaultPrevDisplay.displayString, "⌃ ⌥ ←")
        XCTAssertEqual(CustomShortcut.defaultUndo.displayString, "⌥ ⌘ Z")
    }

    func testResetPerTab() {
        var settings = AppSettings(
            columns: 8,
            rows: 6,
            gap: 20,
            outerMargin: 30,
            avoidStageManager: false,
            stageManagerMargin: 50,
            cycleRepeatedSnaps: false,
            enableSnapZones: false,
            snapZoneTemplate: .threeColumns,
            snapTriggerThreshold: 50,
            overlayShortcut: CustomShortcut(keyCode: 0, carbonModifiers: 0, displayString: "custom")
        )

        // Reset Snap Zones tab only
        settings.resetSnapZones()
        XCTAssertTrue(settings.enableSnapZones)
        XCTAssertEqual(settings.snapZoneTemplate, .twoColumns)
        XCTAssertEqual(settings.snapTriggerThreshold, 25)
        // Others unchanged
        XCTAssertEqual(settings.columns, 8)
        XCTAssertFalse(settings.avoidStageManager)

        // Reset Grid & Gaps tab only
        settings.resetGridAndGaps()
        XCTAssertEqual(settings.columns, 4)
        XCTAssertEqual(settings.rows, 4)
        XCTAssertEqual(settings.gap, 8)
        XCTAssertEqual(settings.outerMargin, 8)
        XCTAssertFalse(settings.avoidStageManager)

        // Reset Behavior tab only
        settings.resetBehavior()
        XCTAssertTrue(settings.avoidStageManager)
        XCTAssertTrue(settings.cycleRepeatedSnaps)

        // Reset Shortcuts tab only
        settings.resetShortcuts()
        XCTAssertEqual(settings.overlayShortcut, CustomShortcut.defaultOverlay)
    }

    func testKeyNames() {
        XCTAssertEqual(CustomShortcut.keyName(for: 49), "Space")
        XCTAssertEqual(CustomShortcut.keyName(for: 36), "↵")
        XCTAssertEqual(CustomShortcut.keyName(for: 17), "T")
        XCTAssertEqual(CustomShortcut.keyName(for: 46), "M")
        XCTAssertEqual(CustomShortcut.keyName(for: 124), "→")
    }
}
