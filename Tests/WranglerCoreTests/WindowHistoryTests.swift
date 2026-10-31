import XCTest
@testable import WranglerCore

final class WindowHistoryTests: XCTestCase {
    func testPushAndPop() {
        let history = WindowHistory(maxEntriesPerWindow: 5)
        let rect1 = CGRect(x: 10, y: 10, width: 400, height: 300)
        let rect2 = CGRect(x: 20, y: 20, width: 500, height: 400)

        history.push(pid: 1234, frame: rect1)
        history.push(pid: 1234, frame: rect2)

        XCTAssertEqual(history.pop(pid: 1234), rect2)
        XCTAssertEqual(history.pop(pid: 1234), rect1)
        XCTAssertNil(history.pop(pid: 1234))
    }

    func testMaxEntriesLimit() {
        let history = WindowHistory(maxEntriesPerWindow: 2)
        history.push(pid: 100, frame: CGRect(x: 1, y: 1, width: 10, height: 10))
        history.push(pid: 100, frame: CGRect(x: 2, y: 2, width: 20, height: 20))
        history.push(pid: 100, frame: CGRect(x: 3, y: 3, width: 30, height: 30))

        // Oldest (1,1) should have been truncated
        XCTAssertEqual(history.pop(pid: 100)?.origin.x, 3)
        XCTAssertEqual(history.pop(pid: 100)?.origin.x, 2)
        XCTAssertNil(history.pop(pid: 100))
    }

    func testDuplicatePushIgnored() {
        let history = WindowHistory()
        let rect = CGRect(x: 50, y: 50, width: 200, height: 200)

        history.push(pid: 200, frame: rect)
        history.push(pid: 200, frame: rect) // duplicate

        XCTAssertEqual(history.pop(pid: 200), rect)
        XCTAssertNil(history.pop(pid: 200))
    }
}

final class LayoutStoreTests: XCTestCase {
    func testStandardPresetsLoaded() {
        let store = LayoutStore()
        XCTAssertNotNil(store.get(id: "left-half"))
        XCTAssertNotNil(store.get(id: "right-half"))
        XCTAssertNotNil(store.get(id: "full"))
        XCTAssertEqual(store.all().count, NamedLayout.standardPresets.count)
    }

    func testEncodeAndDecode() throws {
        let store = LayoutStore()
        let data = try store.encode()

        let freshStore = LayoutStore(defaults: [])
        try freshStore.load(from: data)

        XCTAssertEqual(freshStore.all().count, store.all().count)
        XCTAssertEqual(freshStore.get(id: "left-half"), store.get(id: "left-half"))
    }
}
