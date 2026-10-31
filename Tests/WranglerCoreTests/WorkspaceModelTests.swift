import XCTest
@testable import WranglerCore

final class WorkspaceModelTests: XCTestCase {
    func testSavedWorkspaceEncodingDecoding() throws {
        let slot1 = AppSlot(
            bundleID: "com.apple.Safari",
            appName: "Safari",
            frame: CGRect(x: 0, y: 30, width: 1280, height: 900)
        )
        let slot2 = AppSlot(
            bundleID: "com.apple.Terminal",
            appName: "Terminal",
            frame: CGRect(x: 1280, y: 30, width: 1280, height: 900)
        )

        let workspace = SavedWorkspace(
            name: "Dev Workspace",
            slots: [slot1, slot2]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(workspace)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SavedWorkspace.self, from: data)

        XCTAssertEqual(decoded.name, "Dev Workspace")
        XCTAssertEqual(decoded.slots.count, 2)
        XCTAssertEqual(decoded.slots[0].bundleID, "com.apple.Safari")
        XCTAssertEqual(decoded.slots[0].frame, CGRect(x: 0, y: 30, width: 1280, height: 900))
        XCTAssertEqual(decoded.slots[1].bundleID, "com.apple.Terminal")
    }

    // REGRESSION GUARD: Rectangle Pro App-to-Slot deduplication
    // Guard against duplicate contradictory entries for the same app in a saved workspace
    func testDeduplicateAppSlots() {
        let rawSlots = [
            AppSlot(bundleID: "com.google.Chrome", appName: "Chrome", frame: CGRect(x: 0, y: 30, width: 1280, height: 970)),
            AppSlot(bundleID: "com.google.Chrome", appName: "Chrome", frame: CGRect(x: 1803, y: 743, width: 500, height: 375)),
            AppSlot(bundleID: "org.mozilla.firefox", appName: "Firefox", frame: CGRect(x: 1280, y: 30, width: 1280, height: 970))
        ]

        var seen = Set<String>()
        var deduplicated: [AppSlot] = []
        for s in rawSlots {
            guard !seen.contains(s.bundleID) else { continue }
            seen.insert(s.bundleID)
            deduplicated.append(s)
        }

        XCTAssertEqual(deduplicated.count, 2)
        XCTAssertEqual(deduplicated[0].bundleID, "com.google.Chrome")
        XCTAssertEqual(deduplicated[0].frame, CGRect(x: 0, y: 30, width: 1280, height: 970)) // Main browser frame kept!
        XCTAssertEqual(deduplicated[1].bundleID, "org.mozilla.firefox")
    }

    func testWorkspacePersistenceInAppSettings() {
        var settings = AppSettings.load()
        let initialCount = settings.savedWorkspaces.count

        let testWs = SavedWorkspace(
            name: "Test Persistence WS",
            slots: [
                AppSlot(bundleID: "com.test.app", appName: "TestApp", frame: CGRect(x: 10, y: 10, width: 500, height: 500))
            ]
        )

        settings.savedWorkspaces.append(testWs)
        settings.save()

        let reloaded = AppSettings.load()
        XCTAssertEqual(reloaded.savedWorkspaces.count, initialCount + 1)
        XCTAssertTrue(reloaded.savedWorkspaces.contains(where: { $0.name == "Test Persistence WS" }))
        let saved = reloaded.savedWorkspaces.first(where: { $0.name == "Test Persistence WS" })
        XCTAssertEqual(saved?.slots.count, 1)

        // Clean up
        var cleanupSettings = AppSettings.load()
        cleanupSettings.savedWorkspaces.removeAll { $0.name == "Test Persistence WS" }
        cleanupSettings.save()
    }
}
