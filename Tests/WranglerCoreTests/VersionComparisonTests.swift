import XCTest
@testable import WranglerCore

final class VersionComparisonTests: XCTestCase {
    func isVersion(_ v1: String, newerThan v2: String) -> Bool {
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

    func testSemanticVersionComparison() {
        XCTAssertTrue(isVersion("1.3.1", newerThan: "1.3.0"))
        XCTAssertTrue(isVersion("v1.4.0", newerThan: "1.3.9"))
        XCTAssertTrue(isVersion("2.0.0", newerThan: "1.99.99"))

        XCTAssertFalse(isVersion("1.3.0", newerThan: "1.3.0"))
        XCTAssertFalse(isVersion("1.2.9", newerThan: "1.3.0"))
        XCTAssertFalse(isVersion("0.9.9", newerThan: "1.0.0"))
    }
}
