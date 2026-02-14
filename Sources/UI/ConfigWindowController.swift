import AppKit
import SwiftUI

class ConfigWindowController: NSWindowController {
    convenience init() {
        let configManager = ConfigManager.shared
        let configView = ConfigView(configManager: configManager)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: configView)
        window.title = "QuickWindowSelector Settings"
        window.center()
        
        self.init(window: window)
    }
}
