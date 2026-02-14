import Foundation
import CoreGraphics
import AppKit
import ApplicationServices

final class WindowManager {
    static let shared = WindowManager()
    
    private var titleCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.quickwindowselector.cache")
    private var isInitialLoadComplete = false
    private var refreshTimer: Timer?
    
    private init() {
        startBackgroundRefresh()
    }
    
    func reloadConfig() {
        refreshTimer?.invalidate()
        startBackgroundRefresh()
    }
    
    private var config: AppConfig {
        ConfigManager.shared.config
    }
    
    private var excludedBundleIds: Set<String> {
        Set(config.excludedBundleIds)
    }
    
    private var excludedOwnerNames: Set<String> {
        Set(config.excludedOwnerNames)
    }
    
    private var windowWidthThreshold: Double {
        config.windowWidthThreshold
    }
    
    private func startBackgroundRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: config.cacheRefreshInterval, repeats: true) { [weak self] _ in
            self?.refreshCacheInBackground()
        }
    }
    
    private func refreshCacheInBackground() {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        
        var windows: [WindowInfo] = []
        
        for windowDict in windowList {
            guard let windowLayer = windowDict[kCGWindowLayer as String] as? Int,
                  windowLayer == 0,
                  let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let windowNumber = windowDict[kCGWindowNumber as String] as? Int,
                  ownerPID != ownPID
            else {
                continue
            }
            
            let app = runningApps.first { $0.processIdentifier == ownerPID }
            let bundleId = app?.bundleIdentifier
            
            let title = windowDict[kCGWindowName as String] as? String ?? ""
            
            windows.append(WindowInfo(
                windowNumber: windowNumber,
                ownerPID: ownerPID,
                ownerName: ownerName,
                title: title,
                bundleIdentifier: bundleId
            ))
        }
        
        updateTitleCache(from: windows)
    }
    
    func getVisibleWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        
        var results: [WindowInfo] = []
        
        for windowDict in windowList {
            guard let windowLayer = windowDict[kCGWindowLayer as String] as? Int,
                  windowLayer == 0,
                  let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let windowNumber = windowDict[kCGWindowNumber as String] as? Int
            else {
                continue
            }
            
            if ownerPID == ownPID {
                continue
            }
            
            let bounds = windowDict[kCGWindowBounds as String] as? [String: Double]
            
            if let bounds = bounds, let width = bounds["Width"], width < windowWidthThreshold {
                continue
            }
            
            let app = runningApps.first { $0.processIdentifier == ownerPID }
            let bundleId = app?.bundleIdentifier
            
            if let bundleId = bundleId, excludedBundleIds.contains(bundleId) {
                continue
            }
            
            if excludedOwnerNames.contains(ownerName) {
                continue
            }
            
            // Check cache first, then CGWindowList
            let cacheKey = "\(ownerPID)-\(windowNumber)"
            var title = cacheQueue.sync { titleCache[cacheKey] } ?? ""
            
            // Only use CGWindowList title as fallback
            if title.isEmpty {
                title = windowDict[kCGWindowName as String] as? String ?? ""
            }
            
            results.append(WindowInfo(
                windowNumber: windowNumber,
                ownerPID: ownerPID,
                ownerName: ownerName,
                title: title,
                bundleIdentifier: bundleId
            ))
        }
        
        // Update cache in background (doesn't affect UI)
        DispatchQueue.global(qos: .background).async {
            self.updateTitleCache(from: results)
        }
        
        return results
    }
    
    private func updateTitleCache(from windows: [WindowInfo]) {
        for window in windows {
            let cacheKey = "\(window.ownerPID)-\(window.windowNumber)"
            if !window.title.isEmpty {
                cacheQueue.async {
                    self.titleCache[cacheKey] = window.title
                }
            }
        }
        
        // Also try to get more titles via AX
        var windowsByApp: [pid_t: [WindowInfo]] = [:]
        for window in windows {
            windowsByApp[window.ownerPID, default: []].append(window)
        }
        
        for (pid, appWindows) in windowsByApp {
            let titles = getWindowTitlesSync(for: pid)
            for (index, window) in appWindows.enumerated() {
                if index < titles.count && !titles[index].isEmpty {
                    let cacheKey = "\(window.ownerPID)-\(window.windowNumber)"
                    cacheQueue.async {
                        self.titleCache[cacheKey] = titles[index]
                    }
                }
            }
        }
    }
    
    private func getWindowTitlesSync(for pid: pid_t) -> [String] {
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return []
        }
        
        var titles: [String] = []
        for axWindow in windows {
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef) == .success {
                if let title = titleRef as? String {
                    titles.append(title)
                }
            }
        }
        
        return titles
    }
    
    func preloadWindowsSync() {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        
        var windows: [WindowInfo] = []
        
        for windowDict in windowList {
            guard let windowLayer = windowDict[kCGWindowLayer as String] as? Int,
                  windowLayer == 0,
                  let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let windowNumber = windowDict[kCGWindowNumber as String] as? Int
            else {
                continue
            }
            
            if ownerPID == ownPID {
                continue
            }
            
            let bounds = windowDict[kCGWindowBounds as String] as? [String: Double]
            
            if let bounds = bounds, let width = bounds["Width"], width < windowWidthThreshold {
                continue
            }
            
            let app = runningApps.first { $0.processIdentifier == ownerPID }
            let bundleId = app?.bundleIdentifier
            
            if let bundleId = bundleId, excludedBundleIds.contains(bundleId) {
                continue
            }
            
            if excludedOwnerNames.contains(ownerName) {
                continue
            }
            
            let title = windowDict[kCGWindowName as String] as? String ?? ""
            
            windows.append(WindowInfo(
                windowNumber: windowNumber,
                ownerPID: ownerPID,
                ownerName: ownerName,
                title: title,
                bundleIdentifier: bundleId
            ))
        }
        
        var windowsByApp: [pid_t: [WindowInfo]] = [:]
        for window in windows {
            windowsByApp[window.ownerPID, default: []].append(window)
        }
        
        for (pid, appWindows) in windowsByApp {
            let titles = getWindowTitlesSync(for: pid)
            for (index, window) in appWindows.enumerated() {
                if index < titles.count && !titles[index].isEmpty {
                    let cacheKey = "\(window.ownerPID)-\(window.windowNumber)"
                    cacheQueue.sync {
                        self.titleCache[cacheKey] = titles[index]
                    }
                }
            }
        }
        
        isInitialLoadComplete = true
    }
    
    func activateWindow(_ window: WindowInfo) {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.processIdentifier == window.ownerPID }) else {
            return
        }
        
        app.activate(options: .activateIgnoringOtherApps)
        
        raiseWindow(ownerPID: window.ownerPID)
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.hideSearchPanel()
        }
    }
    
    private func raiseWindow(ownerPID: pid_t) {
        let appElement = AXUIElementCreateApplication(ownerPID)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return
        }
        
        for axWindow in windows {
            AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        }
    }
}
