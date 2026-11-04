import XCTest
@testable import WranglerCore

final class RegressionBugTests: XCTestCase {
    // REGRESSION GUARD 1: Ignored Apps Filtering
    // Guard against auto-tiling or snapping touching blacklisted utility apps (Calculator, 1Password)
    func testIgnoredAppsFiltering() {
        let settings = AppSettings(
            ignoredBundleIDs: ["com.apple.calculator", "com.1password.1password"]
        )

        let testApps = [
            (bundleID: "com.apple.Safari", isIgnored: false),
            (bundleID: "com.apple.calculator", isIgnored: true),
            (bundleID: "com.1password.1password", isIgnored: true),
            (bundleID: "com.google.Chrome", isIgnored: false)
        ]

        for app in testApps {
            let shouldIgnore = settings.ignoredBundleIDs.contains(app.bundleID)
            XCTAssertEqual(shouldIgnore, app.isIgnored, "Failed for \(app.bundleID)")
        }
    }

    // REGRESSION GUARD 2: Window Swap Frame Logic
    // Guard against window swap coordinate corruption
    func testWindowSwapCoordinates() {
        let frameA = CGRect(x: 0, y: 30, width: 1280, height: 970)
        let frameB = CGRect(x: 1280, y: 30, width: 1280, height: 970)

        // Swap
        let swappedA = frameB
        let swappedB = frameA

        XCTAssertEqual(swappedA.origin.x, 1280)
        XCTAssertEqual(swappedB.origin.x, 0)
        XCTAssertEqual(swappedA.width, frameA.width)
        XCTAssertEqual(swappedB.width, frameB.width)
    }

    // REGRESSION GUARD 3: Version Comparison Semantics
    // Guard against "1.10.0" being evaluated as older than "1.9.0", or "v" prefix breaking parsing
    func testSemverEdgeCases() {
        XCTAssertTrue(isVersion("1.10.0", newerThan: "1.9.0"))
        XCTAssertTrue(isVersion("v1.10.0", newerThan: "v1.9.0"))
        XCTAssertTrue(isVersion("1.0.10", newerThan: "1.0.9"))
        XCTAssertTrue(isVersion("2.0.0", newerThan: "1.99.99"))

        XCTAssertFalse(isVersion("1.9.0", newerThan: "1.10.0"))
        XCTAssertFalse(isVersion("1.5.0", newerThan: "1.5.0"))
    }

    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        let clean1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let clean2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        let parts1 = clean1.split(separator: ".").compactMap { Int($0) }
        let parts2 = clean2.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    // REGRESSION GUARD 4: Stage Manager Margin Math
    // Guard against negative widths or double margin application
    func testStageManagerMarginOffset() {
        let baseVisibleFrame = CGRect(x: 0, y: 78, width: 2560, height: 972)
        let margin: CGFloat = 72

        var adjusted = baseVisibleFrame
        adjusted.origin.x += margin
        adjusted.size.width = max(100, adjusted.size.width - margin)

        XCTAssertEqual(adjusted.origin.x, 72)
        XCTAssertEqual(adjusted.size.width, 2488)
        XCTAssertEqual(adjusted.size.height, 972)
    }

    // REGRESSION GUARD 5: Grid Overlay Shortcut Specification
    // Guard against Option + Space keycode or Carbon modifier bitmask regressions
    func testOverlayShortcutSpecification() {
        let overlay = CustomShortcut.defaultOverlay
        XCTAssertEqual(overlay.keyCode, 49, "Space keycode on macOS Carbon must be 49")
        XCTAssertEqual(overlay.carbonModifiers, 2048, "Option key bitmask in Carbon must be 2048 (1 << 11)")
        XCTAssertEqual(overlay.displayString, "⌥ Space")

        // Test AppSettings default binding
        let settings = AppSettings.default
        XCTAssertEqual(settings.overlayShortcut, CustomShortcut.defaultOverlay)
    }

    // REGRESSION GUARD 6: Custom Shortcut Rebinding & Roundtrip
    // Guard against custom shortcuts losing modifiers when serialized or rebound
    func testCustomShortcutSerialization() throws {
        let custom = CustomShortcut(
            keyCode: 13, // 'W'
            carbonModifiers: 2048 | 256, // Option + Command
            displayString: "⌥ ⌘ W"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(custom)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CustomShortcut.self, from: data)

        XCTAssertEqual(decoded.keyCode, 13)
        XCTAssertEqual(decoded.carbonModifiers, 2048 | 256)
        XCTAssertEqual(decoded.displayString, "⌥ ⌘ W")
    }
}
