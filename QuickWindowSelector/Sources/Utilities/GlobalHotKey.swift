import Foundation
import Carbon
import AppKit

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: () -> Void
    
    init(key: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler
        register(key: key, modifiers: modifiers)
    }
    
    deinit {
        unregister()
    }
    
    private func register(key: UInt32, modifiers: UInt32) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                hotKey.handler()
                return noErr
            },
            1,
            &eventType,
            refcon,
            &eventHandler
        )
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5157_5345) // "QWSE"
        hotKeyID.id = 1
        
        let carbonModifiers = carbonModifiersFromCocoaModifiers(modifiers)
        
        RegisterEventHotKey(
            key,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    private func carbonModifiersFromCocoaModifiers(_ modifiers: UInt32) -> UInt32 {
        var carbonMods: UInt32 = 0
        
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 {
            carbonMods |= UInt32(controlKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 {
            carbonMods |= UInt32(optionKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 {
            carbonMods |= UInt32(cmdKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            carbonMods |= UInt32(shiftKey)
        }
        
        return carbonMods
    }
    
    private func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
