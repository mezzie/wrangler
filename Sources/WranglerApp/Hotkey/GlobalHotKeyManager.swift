import AppKit
import Carbon
import WranglerCore

public final class GlobalHotKeyManager {
    public static let shared = GlobalHotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var registeredHotKeys: [UInt32: EventHotKeyRef] = [:]

    public var onHotKeyPressed: (() -> Void)?
    public var onNextDisplayPressed: (() -> Void)?
    public var onPrevDisplayPressed: (() -> Void)?
    public var onAutoTilePressed: (() -> Void)?
    public var onMaximizePressed: (() -> Void)?
    public var onUndoPressed: (() -> Void)?
    public var onSwapPressed: (() -> Void)?
    public var onNumpadPressed: ((String) -> Void)?
    public var onFocusDirectionPressed: ((FocusDirection) -> Void)?
    public var onCycleSameAppPressed: (() -> Void)?

    private init() {}

    /// Registers all global hotkeys from current AppSettings
    public func registerFromSettings(_ settings: AppSettings = .load()) {
        unregisterAllHotKeys()

        if eventHandler == nil {
            installCarbonHandler()
        }

        // 1. Overlay
        registerSingle(id: 1, shortcut: settings.overlayShortcut)

        // 2. Next Display
        registerSingle(id: 2, shortcut: settings.nextDisplayShortcut)

        // 3. Prev Display
        registerSingle(id: 3, shortcut: settings.prevDisplayShortcut)

        // 4. Auto-Tile
        registerSingle(id: 4, shortcut: settings.autoTileShortcut)

        // 5. Maximize
        registerSingle(id: 5, shortcut: settings.maximizeShortcut)

        // 6. Undo
        registerSingle(id: 6, shortcut: settings.undoShortcut)

        // 7. Swap Top Two Windows (⌃ ⌥ S)
        registerSingle(id: 7, shortcut: settings.swapShortcut)

        // Numpad 1-9 (⌃ ⌥ Numpad 1..9)
        if settings.enableNumpadHotkeys {
            let numpadMap: [(UInt32, UInt32)] = [
                (101, 83), // 1: bottom-left
                (102, 84), // 2: bottom-half
                (103, 85), // 3: bottom-right
                (104, 86), // 4: left-half
                (105, 87), // 5: center
                (106, 88), // 6: right-half
                (107, 89), // 7: top-left
                (108, 91), // 8: top-half
                (109, 92)  // 9: top-right
            ]
            let mods = UInt32(controlKey | optionKey)
            for (id, code) in numpadMap {
                registerRaw(id: id, keyCode: code, carbonModifiers: mods)
            }
        }

        // Spatial Focus Navigation (Vim HJKL: ⌃ ⌥ H/L/K/J)
        let ctrlOpt = UInt32(controlKey | optionKey)
        registerRaw(id: 201, keyCode: 4, carbonModifiers: ctrlOpt)  // H: Left
        registerRaw(id: 202, keyCode: 37, carbonModifiers: ctrlOpt) // L: Right
        registerRaw(id: 203, keyCode: 40, carbonModifiers: ctrlOpt) // K: Up
        registerRaw(id: 204, keyCode: 38, carbonModifiers: ctrlOpt) // J: Down

        // Cycle Same-App Windows (⌃ ⌥ `)
        registerRaw(id: 205, keyCode: 50, carbonModifiers: ctrlOpt) // ` (Grave)
    }

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                guard let userData = userData, let event = event else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                switch hotKeyID.id {
                case 1:
                    manager.onHotKeyPressed?()
                case 2:
                    manager.onNextDisplayPressed?()
                case 3:
                    manager.onPrevDisplayPressed?()
                case 4:
                    manager.onAutoTilePressed?()
                case 5:
                    manager.onMaximizePressed?()
                case 6:
                    manager.onUndoPressed?()
                case 7:
                    manager.onSwapPressed?()
                case 101:
                    manager.onNumpadPressed?("bottom-left")
                case 102:
                    manager.onNumpadPressed?("bottom-half")
                case 103:
                    manager.onNumpadPressed?("bottom-right")
                case 104:
                    manager.onNumpadPressed?("left-half")
                case 105:
                    manager.onNumpadPressed?("center")
                case 106:
                    manager.onNumpadPressed?("right-half")
                case 107:
                    manager.onNumpadPressed?("top-left")
                case 108:
                    manager.onNumpadPressed?("top-half")
                case 109:
                    manager.onNumpadPressed?("top-right")
                case 201:
                    manager.onFocusDirectionPressed?(.left)
                case 202:
                    manager.onFocusDirectionPressed?(.right)
                case 203:
                    manager.onFocusDirectionPressed?(.up)
                case 204:
                    manager.onFocusDirectionPressed?(.down)
                case 205:
                    manager.onCycleSameAppPressed?()
                default:
                    break
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        if status != noErr {
            print("Failed to install Carbon event handler: \(status)")
        }
    }

    private func registerSingle(id: UInt32, shortcut: CustomShortcut) {
        registerRaw(id: id, keyCode: shortcut.keyCode, carbonModifiers: shortcut.carbonModifiers)
    }

    private func registerRaw(id: UInt32, keyCode: UInt32, carbonModifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x5752474C), id: id) // "WRGL"
        var hotKeyRef: EventHotKeyRef?
        let regStatus = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if regStatus == noErr, let ref = hotKeyRef {
            registeredHotKeys[id] = ref
        }
    }

    public func unregisterAllHotKeys() {
        for (_, ref) in registeredHotKeys {
            UnregisterEventHotKey(ref)
        }
        registeredHotKeys.removeAll()
    }

    public func unregisterAll() {
        unregisterAllHotKeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregisterAll()
    }
}
