import Foundation

public struct NamedLayout: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let config: GridConfig
    public let selection: GridSelection

    public init(id: String, name: String, config: GridConfig, selection: GridSelection) {
        self.id = id
        self.name = name
        self.config = config
        self.selection = selection
    }

    public static let standardPresets: [NamedLayout] = [
        // Maximize
        NamedLayout(
            id: "full",
            name: "Maximize",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 3, row: 3))
        ),
        // Halves
        NamedLayout(
            id: "left-half",
            name: "Left Half (½)",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 1, row: 3))
        ),
        NamedLayout(
            id: "right-half",
            name: "Right Half (½)",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 2, row: 0), end: GridCellIndex(col: 3, row: 3))
        ),
        NamedLayout(
            id: "top-half",
            name: "Top Half (½)",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 3, row: 1))
        ),
        NamedLayout(
            id: "bottom-half",
            name: "Bottom Half (½)",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 2), end: GridCellIndex(col: 3, row: 3))
        ),
        // Thirds (using 6 columns)
        NamedLayout(
            id: "left-two-thirds",
            name: "Left Two Thirds (⅔)",
            config: GridConfig(columns: 6, rows: 4),
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 3, row: 3))
        ),
        NamedLayout(
            id: "left-one-third",
            name: "Left One Third (⅓)",
            config: GridConfig(columns: 6, rows: 4),
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 1, row: 3))
        ),
        NamedLayout(
            id: "right-two-thirds",
            name: "Right Two Thirds (⅔)",
            config: GridConfig(columns: 6, rows: 4),
            selection: GridSelection(start: GridCellIndex(col: 2, row: 0), end: GridCellIndex(col: 5, row: 3))
        ),
        NamedLayout(
            id: "right-one-third",
            name: "Right One Third (⅓)",
            config: GridConfig(columns: 6, rows: 4),
            selection: GridSelection(start: GridCellIndex(col: 4, row: 0), end: GridCellIndex(col: 5, row: 3))
        ),
        // Quarters
        NamedLayout(
            id: "top-left",
            name: "Top-Left Quarter",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 0), end: GridCellIndex(col: 1, row: 1))
        ),
        NamedLayout(
            id: "top-right",
            name: "Top-Right Quarter",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 2, row: 0), end: GridCellIndex(col: 3, row: 1))
        ),
        NamedLayout(
            id: "bottom-left",
            name: "Bottom-Left Quarter",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 0, row: 2), end: GridCellIndex(col: 1, row: 3))
        ),
        NamedLayout(
            id: "bottom-right",
            name: "Bottom-Right Quarter",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 2, row: 2), end: GridCellIndex(col: 3, row: 3))
        ),
        // Center
        NamedLayout(
            id: "center",
            name: "Center",
            config: .default4x4,
            selection: GridSelection(start: GridCellIndex(col: 1, row: 1), end: GridCellIndex(col: 2, row: 2))
        )
    ]

    /// Returns next preset in cycle when user invokes same shortcut within timeout
    public static func nextCycledPreset(for current: String) -> String {
        switch current {
        case "left-half":
            return "left-two-thirds"
        case "left-two-thirds":
            return "left-one-third"
        case "left-one-third":
            return "left-half"

        case "right-half":
            return "right-two-thirds"
        case "right-two-thirds":
            return "right-one-third"
        case "right-one-third":
            return "right-half"

        default:
            return current
        }
    }
}

public final class LayoutStore: @unchecked Sendable {
    private let lock = NSLock()
    private var layouts: [String: NamedLayout] = [:]

    public init(defaults: [NamedLayout] = NamedLayout.standardPresets) {
        for layout in defaults {
            layouts[layout.id] = layout
        }
    }

    public func get(id: String) -> NamedLayout? {
        lock.lock()
        defer { lock.unlock() }
        return layouts[id]
    }

    public func save(_ layout: NamedLayout) {
        lock.lock()
        defer { lock.unlock() }
        layouts[layout.id] = layout
    }

    public func all() -> [NamedLayout] {
        lock.lock()
        defer { lock.unlock() }
        return Array(layouts.values)
    }

    public func encode() throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(Array(layouts.values))
    }

    public func load(from data: Data) throws {
        let decoder = JSONDecoder()
        let items = try decoder.decode([NamedLayout].self, from: data)
        lock.lock()
        defer { lock.unlock() }
        layouts.removeAll()
        for item in items {
            layouts[item.id] = item
        }
    }
}
