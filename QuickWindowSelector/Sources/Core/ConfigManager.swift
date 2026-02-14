import Foundation
import AppKit
import Carbon
import Combine

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    static let defaultHotkey = HotkeyConfig(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(NSEvent.ModifierFlags.control.rawValue)
    )
}

struct VimHotkeyConfig: Codable, Equatable {
    var moveUp: HotkeyConfig
    var moveDown: HotkeyConfig
    
    static let `default` = VimHotkeyConfig(
        moveUp: HotkeyConfig(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(NSEvent.ModifierFlags.control.rawValue)),
        moveDown: HotkeyConfig(keyCode: UInt32(kVK_ANSI_J), modifiers: UInt32(NSEvent.ModifierFlags.control.rawValue))
    )
}

struct AppConfig: Codable {
    var hotkey: HotkeyConfig
    var vimHotkeys: VimHotkeyConfig
    var cacheRefreshInterval: Double
    var excludedBundleIds: [String]
    var windowWidthThreshold: Double
    var excludedOwnerNames: [String]
    
    static let `default` = AppConfig(
        hotkey: .defaultHotkey,
        vimHotkeys: .default,
        cacheRefreshInterval: 5.0,
        excludedBundleIds: [
            "com.apple.WindowManager",
            Bundle.main.bundleIdentifier ?? ""
        ],
        windowWidthThreshold: 50,
        excludedOwnerNames: ["borders"]
    )
}

final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    private let fileManager = FileManager.default
    
    private static func appSupportPath() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("QuickWindowSelector", isDirectory: true)
    }
    
    private static func configPath() -> URL {
        appSupportPath().appendingPathComponent("config.plist")
    }
    
    var configPath: URL {
        Self.configPath()
    }
    
    @Published var config: AppConfig
    
    private init() {
        let folder = Self.appSupportPath()
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        let path = Self.configPath()
        if fileManager.fileExists(atPath: path.path) {
            if let loaded = Self.load(from: path) {
                self.config = loaded
            } else {
                self.config = AppConfig.default
                save()
            }
        } else {
            self.config = AppConfig.default
            save()
        }
    }
    
    private static func load(from path: URL) -> AppConfig? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path.path) else { return nil }
        
        guard let data = try? Data(contentsOf: path) else { return nil }
        
        let decoder = PropertyListDecoder()
        return try? decoder.decode(AppConfig.self, from: data)
    }
    
    func save() {
        let fileManager = FileManager.default
        let folder = configPath.deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        if let data = try? encoder.encode(config) {
            try? data.write(to: configPath)
        }
    }
    
    func update(_ block: (inout AppConfig) -> Void) {
        var newConfig = config
        block(&newConfig)
        config = newConfig
        save()
    }
}
