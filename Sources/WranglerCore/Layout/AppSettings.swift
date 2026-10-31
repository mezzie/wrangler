import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var columns: Int
    public var rows: Int
    public var gap: CGFloat
    public var outerMargin: CGFloat
    public var avoidStageManager: Bool
    public var stageManagerMargin: CGFloat
    public var cycleRepeatedSnaps: Bool

    public init(
        columns: Int = 4,
        rows: Int = 4,
        gap: CGFloat = 8,
        outerMargin: CGFloat = 8,
        avoidStageManager: Bool = true,
        stageManagerMargin: CGFloat = 72,
        cycleRepeatedSnaps: Bool = true
    ) {
        self.columns = max(2, min(columns, 16))
        self.rows = max(1, min(rows, 16))
        self.gap = max(0, min(gap, 64))
        self.outerMargin = max(0, min(outerMargin, 64))
        self.avoidStageManager = avoidStageManager
        self.stageManagerMargin = stageManagerMargin
        self.cycleRepeatedSnaps = cycleRepeatedSnaps
    }

    public static let `default` = AppSettings()

    private static let userDefaultsKey = "com.rngo.wrangler.settings"

    public static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    public var asGridConfig: GridConfig {
        GridConfig(columns: columns, rows: rows, gap: gap, outerMargin: outerMargin)
    }
}
