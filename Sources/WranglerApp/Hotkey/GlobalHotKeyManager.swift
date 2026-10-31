import AppKit
import Carbon

public final class GlobalHotKeyManager {
    public static let shared = GlobalHotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    public var onHotKeyPressed: (() -> Void)?

    private init() {}

    /// Registers global hotkey (Default: Option + Space, or custom key/modifiers)
    /// KeyCode 49 is Space. Modifiers: optionKey (2048) or control/cmd
    public func registerDefaultHotKey(keyCode: UInt32 = 49, carbonModifiers: UInt32 = UInt32(optionKey)) {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onHotKeyPressed?()
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

        let hotKeyID = EventHotKeyID(signature: OSType(0x5752474C), id: 1) // "WRGL"
        let regStatus = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if regStatus != noErr {
            print("Failed to register Carbon EventHotKey: \(regStatus)")
        }
    }

    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
