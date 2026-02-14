import AppKit
import SwiftUI
import Carbon

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var globalHotKey: GlobalHotKey?
    private var searchWindowController: SearchWindowController?
    private var configWindowController: ConfigWindowController?
    private var statusItem: NSStatusItem?
    private var hasPreloaded = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGlobalHotKey()
        setupStatusBarItem()
        NSApp.setActivationPolicy(.accessory)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigChange),
            name: .configDidChange,
            object: nil
        )
    }
    
    @objc private func handleConfigChange() {
        WindowManager.shared.reloadConfig()
        reloadHotKey()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "QuickWindowSelector")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Search", action: #selector(openSearchFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openConfigFile), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func openConfigFile() {
        if configWindowController == nil {
            configWindowController = ConfigWindowController()
        }
        configWindowController?.showWindow(nil)
        configWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func statusBarButtonClicked() {
        toggleSearchPanel()
    }
    
    @objc private func openSearchFromMenu() {
        toggleSearchPanel()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupGlobalHotKey() {
        let config = ConfigManager.shared.config
        globalHotKey = GlobalHotKey(
            key: config.hotkey.keyCode,
            modifiers: config.hotkey.modifiers
        ) { [weak self] in
            self?.toggleSearchPanel()
        }
    }
    
    func reloadHotKey() {
        globalHotKey = nil
        setupGlobalHotKey()
    }
    
    func toggleSearchPanel() {
        if let controller = searchWindowController, let window = controller.window, window.isVisible {
            hideSearchPanel()
        } else {
            showSearchPanelInternal()
        }
    }
    
    private func showSearchPanelInternal() {
        if !hasPreloaded {
            hasPreloaded = true
            WindowManager.shared.preloadWindowsSync()
        }
        
        let controller = SearchWindowController()
        controller.viewModel.onSelect = { window in
            WindowManager.shared.activateWindow(window)
            controller.close()
        }
        controller.viewModel.onEscape = {
            controller.close()
        }
        searchWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideSearchPanel() {
        searchWindowController?.close()
    }
}
