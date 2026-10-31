import AppKit
import Carbon
import Foundation

public struct CustomShortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    public var displayString: String

    public init(keyCode: UInt32, carbonModifiers: UInt32, displayString: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayString = displayString
    }

    public static let defaultOverlay = CustomShortcut(
        keyCode: 49,
        carbonModifiers: UInt32(optionKey),
        displayString: "⌥ Space"
    )

    public static let defaultMaximize = CustomShortcut(
        keyCode: 36,
        carbonModifiers: UInt32(controlKey | optionKey),
        displayString: "⌃ ⌥ ↵"
    )

    public static let defaultAutoTile = CustomShortcut(
        keyCode: 17,
        carbonModifiers: UInt32(controlKey | optionKey),
        displayString: "⌃ ⌥ T"
    )

    public static let defaultNextDisplay = CustomShortcut(
        keyCode: 124,
        carbonModifiers: UInt32(controlKey | optionKey),
        displayString: "⌃ ⌥ →"
    )

    public static let defaultPrevDisplay = CustomShortcut(
        keyCode: 123,
        carbonModifiers: UInt32(controlKey | optionKey),
        displayString: "⌃ ⌥ ←"
    )

    public static let defaultUndo = CustomShortcut(
        keyCode: 6,
        carbonModifiers: UInt32(optionKey | cmdKey),
        displayString: "⌥ ⌘ Z"
    )

    /// Converts an NSEvent keydown into a CustomShortcut
    public static func from(event: NSEvent) -> CustomShortcut? {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        // Must have at least one modifier key (command, option, or control)
        guard !flags.intersection([.command, .option, .control]).isEmpty else {
            return nil
        }

        var carbonMods: UInt32 = 0
        var modString = ""

        if flags.contains(.control) {
            carbonMods |= UInt32(controlKey)
            modString += "⌃ "
        }
        if flags.contains(.option) {
            carbonMods |= UInt32(optionKey)
            modString += "⌥ "
        }
        if flags.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
            modString += "⇧ "
        }
        if flags.contains(.command) {
            carbonMods |= UInt32(cmdKey)
            modString += "⌘ "
        }

        let keyStr = keyName(for: event.keyCode)
        let fullDisplay = "\(modString)\(keyStr)"

        return CustomShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonMods,
            displayString: fullDisplay
        )
    }

    public static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 49: return "Space"
        case 36: return "↵"
        case 53: return "ESC"
        case 48: return "Tab"
        case 51: return "⌫"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        default: return "Key \(keyCode)"
        }
    }
}
