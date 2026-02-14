import SwiftUI
import AppKit
import Carbon

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    var isRecording: Binding<Bool>
    
    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.keyCode = keyCode
        view.modifiers = modifiers
        view.isRecording = isRecording
        view.onKeyChange = { newKeyCode, newModifiers in
            keyCode = newKeyCode
            modifiers = newModifiers
        }
        return view
    }
    
    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        nsView.keyCode = keyCode
        nsView.modifiers = modifiers
        nsView.isRecording = isRecording
        nsView.updateDisplay()
    }
}

class HotkeyRecorderNSView: NSView {
    var keyCode: UInt32 = 0
    var modifiers: UInt32 = 0
    var isRecording: Binding<Bool> = .constant(false)
    var onKeyChange: ((UInt32, UInt32) -> Void)?
    
    private var isCapturing = false
    
    override var acceptsFirstResponder: Bool { true }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        updateDisplay()
    }
    
    func updateDisplay() {
        if keyCode == 0 && modifiers == 0 {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        } else {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
        }
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        isCapturing = true
        isRecording.wrappedValue = true
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        guard isCapturing else {
            super.keyDown(with: event)
            return
        }
        
        let newKeyCode = UInt32(event.keyCode)
        let newModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        
        if newKeyCode == UInt32(kVK_Escape) || (newKeyCode == UInt32(kVK_Return) && newModifiers == 0) {
            cancelCapture()
            return
        }
        
        if newModifiers != 0 && newKeyCode != UInt32(kVK_UpArrow) && newKeyCode != UInt32(kVK_DownArrow) {
            keyCode = newKeyCode
            modifiers = UInt32(newModifiers)
            onKeyChange?(keyCode, modifiers)
        }
        
        isCapturing = false
        isRecording.wrappedValue = false
        updateDisplay()
    }
    
    override func flagsChanged(with event: NSEvent) {
        if !isCapturing {
            super.flagsChanged(with: event)
        }
    }
    
    private func cancelCapture() {
        isCapturing = false
        isRecording.wrappedValue = false
        updateDisplay()
    }
    
    override func resignFirstResponder() -> Bool {
        isCapturing = false
        isRecording.wrappedValue = false
        updateDisplay()
        return super.resignFirstResponder()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let text = displayString()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        
        let size = text.size(withAttributes: attributes)
        let rect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        
        text.draw(in: rect, withAttributes: attributes)
    }
    
    private func displayString() -> String {
        var parts: [String] = []
        
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 {
            parts.append("⌘")
        }
        
        let keyName = keyCodeToString(keyCode)
        parts.append(keyName)
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ code: UInt32) -> String {
        switch code {
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "↩"
        case UInt32(kVK_Tab): return "⇥"
        case UInt32(kVK_Delete): return "⌫"
        case UInt32(kVK_Escape): return "⎋"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_F1): return "F1"
        case UInt32(kVK_F2): return "F2"
        case UInt32(kVK_F3): return "F3"
        case UInt32(kVK_F4): return "F4"
        case UInt32(kVK_F5): return "F5"
        case UInt32(kVK_F6): return "F6"
        case UInt32(kVK_F7): return "F7"
        case UInt32(kVK_F8): return "F8"
        case UInt32(kVK_F9): return "F9"
        case UInt32(kVK_F10): return "F10"
        case UInt32(kVK_F11): return "F11"
        case UInt32(kVK_F12): return "F12"
        default:
            if let char = keyCodeToChar(code) {
                return char.uppercased()
            }
            return "?"
        }
    }
    
    private func keyCodeToChar(_ code: UInt32) -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let dataRef = unsafeBitCast(layoutData, to: CFData.self)
        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)
        
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length: Int = 0
        
        let status = UCKeyTranslate(
            keyboardLayout,
            UInt16(code),
            UInt16(kUCKeyActionDown),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )
        
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}
