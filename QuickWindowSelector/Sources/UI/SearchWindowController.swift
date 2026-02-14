import AppKit
import SwiftUI
import Combine
import Carbon

class SearchWindowController: NSWindowController, NSWindowDelegate {
    let viewModel = SearchViewModel()
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    convenience init() {
        let contentRect = NSRect(x: 0, y: 0, width: 600, height: 400)
        let panel = FloatingPanel(contentRect: contentRect)
        
        self.init(window: panel)
        panel.delegate = self
        
        let searchView = SearchView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: searchView)
        hosting.frame = contentRect
        panel.contentView = hosting
        
        panel.center()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        viewModel.searchText = ""
        viewModel.loadWindows()
        
        window?.makeKeyAndOrderFront(nil)
        
        let vimHotkeys = ConfigManager.shared.config.vimHotkeys
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.window?.isKeyWindow == true else { return event }
            
            let keyCode = UInt32(event.keyCode)
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            
            switch event.keyCode {
            case 125: // Down arrow
                self.viewModel.moveSelectionDown()
                return nil
            case 126: // Up arrow
                self.viewModel.moveSelectionUp()
                return nil
            case 36: // Return
                self.viewModel.confirmSelection()
                return nil
            case 53: // Escape
                self.viewModel.onEscape?()
                return nil
            default:
                if keyCode == vimHotkeys.moveDown.keyCode && modifiers == vimHotkeys.moveDown.modifiers {
                    self.viewModel.moveSelectionDown()
                    return nil
                }
                if keyCode == vimHotkeys.moveUp.keyCode && modifiers == vimHotkeys.moveUp.modifiers {
                    self.viewModel.moveSelectionUp()
                    return nil
                }
                return event
            }
        }
    }
    
    override func close() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        super.close()
    }
    
    func windowWillClose(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            filterWindows()
        }
    }
    @Published var allWindows: [WindowInfo] = []
    @Published var filteredWindows: [WindowInfo] = []
    @Published var selectedIndex: Int = 0
    
    var onSelect: ((WindowInfo) -> Void)?
    var onEscape: (() -> Void)?
    
    func loadWindows() {
        allWindows = WindowManager.shared.getVisibleWindows()
        filterWindows()
    }
    
    func filterWindows() {
        if searchText.isEmpty {
            filteredWindows = allWindows
        } else {
            filteredWindows = FuzzySearch.search(query: searchText, in: allWindows)
        }
        if selectedIndex >= filteredWindows.count {
            selectedIndex = max(0, filteredWindows.count - 1)
        }
    }
    
    func moveSelectionDown() {
        if selectedIndex < filteredWindows.count - 1 {
            selectedIndex += 1
        }
    }
    
    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func confirmSelection() {
        guard selectedIndex < filteredWindows.count else { return }
        let window = filteredWindows[selectedIndex]
        onSelect?(window)
    }
}
