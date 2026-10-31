import AppKit
import Carbon

public final class GlobalHotKeyManager {
    public static let shared = GlobalHotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var registeredHotKeys: [UInt32: EventHotKeyRef] = [:]

    public var onHotKeyPressed: (() -> Void)?
    public var onNextDisplayPressed: (() -> Void)?
    public var onPrevDisplayPressed: (() -> Void)?

    private init() {}

    /// Registers standard global hotkeys
    public func registerDefaultHotKeys() {
        unregisterAll()

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

        guard status == noErr else {
            print("Failed to install Carbon event handler: \(status)")
            return
        }

        // 1. Option + Space -> Show Grid Overlay
        registerSingleHotKey(id: 1, keyCode: 49, carbonModifiers: UInt32(optionKey))

        // 2. Control + Option + Right Arrow (124) -> Next Display
        registerSingleHotKey(id: 2, keyCode: 124, carbonModifiers: UInt32(controlKey | optionKey))

        // 3. Control + Option + Left Arrow (123) -> Previous Display
        registerSingleHotKey(id: 3, keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))
    }

    private func registerSingleHotKey(id: UInt32, keyCode: UInt32, carbonModifiers: UInt32) {
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

    public func unregisterAll() {
        for (_, ref) in registeredHotKeys {
            UnregisterEventHotKey(ref)
        }
        registeredHotKeys.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregisterAll()
    }
}
