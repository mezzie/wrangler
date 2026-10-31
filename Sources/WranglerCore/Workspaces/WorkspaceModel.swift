import Foundation
import CoreGraphics

public struct AppSlot: Codable, Equatable, Sendable {
    public let bundleID: String
    public let appName: String
    public let frame: CGRect

    public init(bundleID: String, appName: String, frame: CGRect) {
        self.bundleID = bundleID
        self.appName = appName
        self.frame = frame
    }
}

public struct SavedWorkspace: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public let createdAt: Date
    public let slots: [AppSlot]

    public init(
        id: String = UUID().uuidString,
        name: String,
        createdAt: Date = Date(),
        slots: [AppSlot]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.slots = slots
    }
}
