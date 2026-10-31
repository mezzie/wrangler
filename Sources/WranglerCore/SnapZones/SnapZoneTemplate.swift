import Foundation

public enum SnapZoneTemplate: String, Codable, CaseIterable, Sendable {
    case twoColumns = "two_columns"         // 50% / 50%
    case threeColumns = "three_columns"     // 33% / 33% / 33%
    case ultrawideFocus = "ultrawide_focus" // 25% | 50% | 25%

    public var displayName: String {
        switch self {
        case .twoColumns:
            return "50% / 50% Split (Wide Screens)"
        case .threeColumns:
            return "Three Columns (33% / 33% / 33%)"
        case .ultrawideFocus:
            return "Ultrawide Center Focus (25% | 50% | 25%)"
        }
    }
}
