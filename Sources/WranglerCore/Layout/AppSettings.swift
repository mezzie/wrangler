import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var columns: Int
    public var rows: Int
    public var gap: CGFloat
    public var outerMargin: CGFloat
    public var avoidStageManager: Bool
    public var stageManagerMargin: CGFloat
    public var cycleRepeatedSnaps: Bool
    public var enableSnapZones: Bool
    public var snapZoneTemplate: SnapZoneTemplate
    public var snapTriggerThreshold: CGFloat
    public var appLanguage: String
    public var ignoredBundleIDs: [String]
    public var savedWorkspaces: [SavedWorkspace]
    public var shakeToSummon: Bool
    public var modifierHoldSnap: Bool
    public var enableNumpadHotkeys: Bool
    public var animateWindowSnapping: Bool

    // Customizable Shortcuts
    public var overlayShortcut: CustomShortcut
    public var maximizeShortcut: CustomShortcut
    public var autoTileShortcut: CustomShortcut
    public var nextDisplayShortcut: CustomShortcut
    public var prevDisplayShortcut: CustomShortcut
    public var undoShortcut: CustomShortcut
    public var swapShortcut: CustomShortcut

    public init(
        columns: Int = 4,
        rows: Int = 4,
        gap: CGFloat = 8,
        outerMargin: CGFloat = 8,
        avoidStageManager: Bool = true,
        stageManagerMargin: CGFloat = 72,
        cycleRepeatedSnaps: Bool = true,
        enableSnapZones: Bool = true,
        snapZoneTemplate: SnapZoneTemplate = .twoColumns,
        snapTriggerThreshold: CGFloat = 25,
        appLanguage: String = "system",
        ignoredBundleIDs: [String] = ["com.apple.calculator", "com.1password.1password"],
        savedWorkspaces: [SavedWorkspace] = [],
        shakeToSummon: Bool = false,
        modifierHoldSnap: Bool = true,
        enableNumpadHotkeys: Bool = true,
        animateWindowSnapping: Bool = false,
        overlayShortcut: CustomShortcut = .defaultOverlay,
        maximizeShortcut: CustomShortcut = .defaultMaximize,
        autoTileShortcut: CustomShortcut = .defaultAutoTile,
        nextDisplayShortcut: CustomShortcut = .defaultNextDisplay,
        prevDisplayShortcut: CustomShortcut = .defaultPrevDisplay,
        undoShortcut: CustomShortcut = .defaultUndo,
        swapShortcut: CustomShortcut = .defaultSwap
    ) {
        self.columns = max(2, min(columns, 16))
        self.rows = max(1, min(rows, 16))
        self.gap = max(0, min(gap, 64))
        self.outerMargin = max(0, min(outerMargin, 64))
        self.avoidStageManager = avoidStageManager
        self.stageManagerMargin = stageManagerMargin
        self.cycleRepeatedSnaps = cycleRepeatedSnaps
        self.enableSnapZones = enableSnapZones
        self.snapZoneTemplate = snapZoneTemplate
        self.snapTriggerThreshold = max(10, min(snapTriggerThreshold, 100))
        self.appLanguage = appLanguage
        self.ignoredBundleIDs = ignoredBundleIDs
        self.savedWorkspaces = savedWorkspaces
        self.shakeToSummon = shakeToSummon
        self.modifierHoldSnap = modifierHoldSnap
        self.enableNumpadHotkeys = enableNumpadHotkeys
        self.animateWindowSnapping = animateWindowSnapping
        self.overlayShortcut = overlayShortcut
        self.maximizeShortcut = maximizeShortcut
        self.autoTileShortcut = autoTileShortcut
        self.nextDisplayShortcut = nextDisplayShortcut
        self.prevDisplayShortcut = prevDisplayShortcut
        self.undoShortcut = undoShortcut
        self.swapShortcut = swapShortcut
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

    // MARK: - Restore Defaults Per Tab

    public mutating func resetSnapZones() {
        self.enableSnapZones = true
        self.snapZoneTemplate = .twoColumns
        self.snapTriggerThreshold = 25
    }

    public mutating func resetGridAndGaps() {
        self.columns = 4
        self.rows = 4
        self.gap = 8
        self.outerMargin = 8
    }

    public mutating func resetBehavior() {
        self.avoidStageManager = true
        self.stageManagerMargin = 72
        self.cycleRepeatedSnaps = true
        self.animateWindowSnapping = false
        self.appLanguage = "system"
        self.ignoredBundleIDs = ["com.apple.calculator", "com.1password.1password"]
    }

    public mutating func resetShortcuts() {
        self.overlayShortcut = .defaultOverlay
        self.maximizeShortcut = .defaultMaximize
        self.autoTileShortcut = .defaultAutoTile
        self.nextDisplayShortcut = .defaultNextDisplay
        self.prevDisplayShortcut = .defaultPrevDisplay
        self.undoShortcut = .defaultUndo
        self.swapShortcut = .defaultSwap
    }

    public var asGridConfig: GridConfig {
        GridConfig(columns: columns, rows: rows, gap: gap, outerMargin: outerMargin)
    }
}
