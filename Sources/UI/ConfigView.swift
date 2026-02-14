import SwiftUI
import AppKit
import Carbon

struct ConfigView: View {
    @ObservedObject var configManager: ConfigManager
    @Environment(\.dismiss) private var dismiss
    @State private var editingConfig: AppConfig
    @State private var recordingHotkey: String? = nil
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        _editingConfig = State(initialValue: configManager.config)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Hotkey") {
                    HStack {
                        Text("Show Window")
                        Spacer()
                        hotkeyField(hotkey: $editingConfig.hotkey, id: "show")
                    }
                    
                    Text("Click record, then press your desired key combination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Navigation Hotkeys") {
                    HStack {
                        Text("Move Up")
                        Spacer()
                        hotkeyField(hotkey: $editingConfig.vimHotkeys.moveUp, id: "moveUp")
                    }
                    
                    HStack {
                        Text("Move Down")
                        Spacer()
                        hotkeyField(hotkey: $editingConfig.vimHotkeys.moveDown, id: "moveDown")
                    }
                    
                    Text("Arrow keys always work for navigation. Default: ⌃K (up), ⌃J (down)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Cache") {
                    Picker("Refresh Interval", selection: $editingConfig.cacheRefreshInterval) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("Disabled").tag(0.0)
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Filtering") {
                    HStack {
                        Text("Hide Small Windows")
                        Spacer()
                        TextField("", value: $editingConfig.windowWidthThreshold, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("px wide or less")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Windows smaller than this (in pixels) will be hidden from the list")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Excluded Apps") {
                    ForEach(Array(editingConfig.excludedBundleIds.enumerated()), id: \.offset) { index, bundleId in
                        HStack {
                            Text(bundleId)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button(action: {
                                editingConfig.excludedBundleIds.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Button(action: {
                        editingConfig.excludedBundleIds.append("com.example.app")
                    }) {
                        Label("Add App Bundle ID", systemImage: "plus.circle")
                    }
                }
                
                Section("Excluded Window Owners") {
                    ForEach(Array(editingConfig.excludedOwnerNames.enumerated()), id: \.offset) { index, name in
                        HStack {
                            Text(name)
                            Spacer()
                            Button(action: {
                                editingConfig.excludedOwnerNames.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Button(action: {
                        editingConfig.excludedOwnerNames.append("NewApp")
                    }) {
                        Label("Add Window Owner", systemImage: "plus.circle")
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            
            Divider()
            
            HStack {
                Button("Restore Defaults") {
                    editingConfig = AppConfig.default
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Save") {
                    configManager.config = editingConfig
                    configManager.save()
                    NotificationCenter.default.post(name: .configDidChange, object: nil)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    @ViewBuilder
    private func hotkeyField(hotkey: Binding<HotkeyConfig>, id: String) -> some View {
        HStack(spacing: 8) {
            Text(hotkeyDisplayString(keyCode: hotkey.wrappedValue.keyCode, modifiers: hotkey.wrappedValue.modifiers))
                .frame(width: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(recordingHotkey == id ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(recordingHotkey == id ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: recordingHotkey == id ? 2 : 1)
                )
            
            Button(recordingHotkey == id ? "Press keys..." : "Record") {
                recordingHotkey = recordingHotkey == id ? nil : id
            }
            .buttonStyle(.bordered)
            .tint(recordingHotkey == id ? .red : nil)
        }
        .popover(isPresented: .constant(recordingHotkey == id)) {
            VStack(spacing: 12) {
                Text("Press a key combination")
                    .font(.headline)
                Text("Press Escape to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200, height: 80)
            .contentShape(Rectangle())
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    guard recordingHotkey == id else { return event }
                    
                    let keyCode = UInt32(event.keyCode)
                    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
                    
                    if keyCode == UInt32(kVK_Escape) {
                        recordingHotkey = nil
                        return nil
                    }
                    
                    if keyCode != UInt32(kVK_UpArrow) && keyCode != UInt32(kVK_DownArrow) && modifiers != 0 {
                        hotkey.wrappedValue = HotkeyConfig(keyCode: keyCode, modifiers: UInt32(modifiers))
                        recordingHotkey = nil
                        return nil
                    }
                    
                    return event
                }
            }
        }
    }
    
    private func hotkeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
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
        
        parts.append(keyCodeToString(keyCode))
        
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
