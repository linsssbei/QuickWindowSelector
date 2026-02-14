import Testing
import Foundation
import Combine
import AppKit
import Carbon
@testable import App

@Suite final class HotkeyConfigTests {
    
    @Test func defaultHotkeyHasCorrectKeyCode() {
        #expect(HotkeyConfig.defaultHotkey.keyCode == UInt32(kVK_Space))
    }
    
    @Test func defaultHotkeyHasCorrectModifiers() {
        #expect(HotkeyConfig.defaultHotkey.modifiers == UInt32(NSEvent.ModifierFlags.control.rawValue))
    }
    
    @Test func hotkeyConfigIsEquatable() {
        let h1 = HotkeyConfig(keyCode: 49, modifiers: 262144)
        let h2 = HotkeyConfig(keyCode: 49, modifiers: 262144)
        let h3 = HotkeyConfig(keyCode: 48, modifiers: 262144)
        
        #expect(h1 == h2)
        #expect(h1 != h3)
    }
    
    @Test func hotkeyConfigCodable() throws {
        let config = HotkeyConfig(keyCode: 100, modifiers: 200)
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(config)
        
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(HotkeyConfig.self, from: data)
        
        #expect(decoded.keyCode == 100)
        #expect(decoded.modifiers == 200)
    }
}

@Suite final class VimHotkeyConfigTests {
    
    @Test func defaultVimHotkeysMoveUpIsControlK() {
        #expect(VimHotkeyConfig.default.moveUp.keyCode == UInt32(kVK_ANSI_K))
    }
    
    @Test func defaultVimHotkeysMoveDownIsControlJ() {
        #expect(VimHotkeyConfig.default.moveDown.keyCode == UInt32(kVK_ANSI_J))
    }
    
    @Test func vimHotkeyConfigIsEquatable() {
        let v1 = VimHotkeyConfig.default
        let v2 = VimHotkeyConfig.default
        
        #expect(v1 == v2)
    }
    
    @Test func vimHotkeyConfigCodable() throws {
        let config = VimHotkeyConfig(
            moveUp: HotkeyConfig(keyCode: 1, modifiers: 2),
            moveDown: HotkeyConfig(keyCode: 3, modifiers: 4)
        )
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(config)
        
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(VimHotkeyConfig.self, from: data)
        
        #expect(decoded.moveUp.keyCode == 1)
        #expect(decoded.moveDown.keyCode == 3)
    }
}

@Suite final class AppConfigTests {
    
    @Test func defaultConfigHasCorrectHotkey() {
        #expect(AppConfig.default.hotkey.keyCode == UInt32(kVK_Space))
    }
    
    @Test func defaultConfigHasCorrectVimHotkeys() {
        #expect(AppConfig.default.vimHotkeys.moveUp.keyCode == UInt32(kVK_ANSI_K))
        #expect(AppConfig.default.vimHotkeys.moveDown.keyCode == UInt32(kVK_ANSI_J))
    }
    
    @Test func defaultConfigHasCorrectCacheRefreshInterval() {
        #expect(AppConfig.default.cacheRefreshInterval == 5.0)
    }
    
    @Test func defaultConfigHasCorrectWindowWidthThreshold() {
        #expect(AppConfig.default.windowWidthThreshold == 50)
    }
    
    @Test func defaultConfigHasExcludedBundleIds() {
        #expect(AppConfig.default.excludedBundleIds.count >= 1)
    }
    
    @Test func defaultConfigHasExcludedOwnerNames() {
        #expect(AppConfig.default.excludedOwnerNames.contains("borders"))
    }
    
    @Test func appConfigCodable() throws {
        let config = AppConfig(
            hotkey: HotkeyConfig(keyCode: 10, modifiers: 20),
            vimHotkeys: VimHotkeyConfig(
                moveUp: HotkeyConfig(keyCode: 30, modifiers: 40),
                moveDown: HotkeyConfig(keyCode: 50, modifiers: 60)
            ),
            cacheRefreshInterval: 10.0,
            excludedBundleIds: ["com.test.App"],
            windowWidthThreshold: 100,
            excludedOwnerNames: ["test"]
        )
        
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(config)
        
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(AppConfig.self, from: data)
        
        #expect(decoded.hotkey.keyCode == 10)
        #expect(decoded.vimHotkeys.moveUp.keyCode == 30)
        #expect(decoded.cacheRefreshInterval == 10.0)
        #expect(decoded.windowWidthThreshold == 100)
        #expect(decoded.excludedBundleIds == ["com.test.App"])
    }
}

@Suite final class SearchViewModelTests {
    
    @Test func filterWindowsShowsAllWhenQueryEmpty() {
        let viewModel = SearchViewModel()
        viewModel.allWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab1", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "Tab2", bundleIdentifier: "com.google.Chrome")
        ]
        viewModel.searchText = ""
        
        #expect(viewModel.filteredWindows.count == 2)
    }
    
    @Test func filterWindowsFiltersByQuery() {
        let viewModel = SearchViewModel()
        viewModel.allWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab1", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "Tab2", bundleIdentifier: "com.google.Chrome")
        ]
        viewModel.searchText = "safari"
        
        #expect(viewModel.filteredWindows.count == 1)
        #expect(viewModel.filteredWindows.first?.ownerName == "Safari")
    }
    
    @Test func moveSelectionDownIncrementsIndex() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "", bundleIdentifier: "com.google.Chrome")
        ]
        viewModel.selectedIndex = 0
        
        viewModel.moveSelectionDown()
        
        #expect(viewModel.selectedIndex == 1)
    }
    
    @Test func moveSelectionDownAtEndDoesNotChange() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari")
        ]
        viewModel.selectedIndex = 0
        
        viewModel.moveSelectionDown()
        
        #expect(viewModel.selectedIndex == 0)
    }
    
    @Test func moveSelectionUpDecrementsIndex() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "", bundleIdentifier: "com.google.Chrome")
        ]
        viewModel.selectedIndex = 1
        
        viewModel.moveSelectionUp()
        
        #expect(viewModel.selectedIndex == 0)
    }
    
    @Test func moveSelectionUpAtStartDoesNotChange() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari")
        ]
        viewModel.selectedIndex = 0
        
        viewModel.moveSelectionUp()
        
        #expect(viewModel.selectedIndex == 0)
    }
    
    @Test func selectedIndexResetsWhenFilteredCountReduces() {
        let viewModel = SearchViewModel()
        viewModel.allWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "", bundleIdentifier: "com.google.Chrome")
        ]
        viewModel.selectedIndex = 1
        
        viewModel.searchText = "safari"
        
        #expect(viewModel.selectedIndex == 0)
    }
    
    @Test func selectedIndexStaysValidWhenAllWindowsRemoved() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = []
        viewModel.selectedIndex = 0
        
        viewModel.moveSelectionDown()
        
        #expect(viewModel.selectedIndex == 0)
    }
    
    @Test func confirmSelectionCallsOnSelect() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab", bundleIdentifier: "com.apple.Safari")
        ]
        viewModel.selectedIndex = 0
        
        var selectedWindow: WindowInfo?
        viewModel.onSelect = { window in
            selectedWindow = window
        }
        
        viewModel.confirmSelection()
        
        #expect(selectedWindow?.ownerName == "Safari")
    }
    
    @Test func confirmSelectionDoesNothingWhenEmpty() {
        let viewModel = SearchViewModel()
        viewModel.filteredWindows = []
        viewModel.selectedIndex = 0
        
        var called = false
        viewModel.onSelect = { _ in
            called = true
        }
        
        viewModel.confirmSelection()
        
        #expect(called == false)
    }
}

@Suite final class FuzzySearchTests {
    
    @Test func exactMatch() {
        let score = FuzzySearch.score(query: "safari", target: "Safari")
        #expect(score == 1000)
    }
    
    @Test func exactMatchCaseInsensitive() {
        let score = FuzzySearch.score(query: "SAFARI", target: "safari")
        #expect(score == 1000)
    }
    
    @Test func prefixMatch() {
        let score = FuzzySearch.score(query: "saf", target: "Safari")
        #expect(score > 800)
    }
    
    @Test func partialMatch() {
        let score = FuzzySearch.score(query: "ari", target: "Safari")
        #expect(score > 0)
    }
    
    @Test func noMatch() {
        let score = FuzzySearch.score(query: "xyz", target: "Safari")
        #expect(score == 0)
    }
    
    @Test func emptyQuery() {
        let score = FuzzySearch.score(query: "", target: "Safari")
        #expect(score == 100)
    }
    
    @Test func substringMatch() {
        let score = FuzzySearch.score(query: "foo", target: "foobar")
        #expect(score > 0)
    }
    
    @Test func searchReturnsEmptyForNoMatch() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Apple", bundleIdentifier: "com.apple.Safari")
        ]
        let results = FuzzySearch.search(query: "xyz", in: windows)
        #expect(results.isEmpty)
    }
    
    @Test func searchReturnsAllForEmptyQuery() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Apple", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "Google", bundleIdentifier: "com.google.Chrome")
        ]
        let results = FuzzySearch.search(query: "", in: windows)
        #expect(results.count == 2)
    }
    
    @Test func searchSortsByRelevance() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Browser", bundleIdentifier: "com.apple.Safari"),
            WindowInfo(windowNumber: 2, ownerPID: 101, ownerName: "Chrome", title: "Google", bundleIdentifier: "com.google.Chrome"),
            WindowInfo(windowNumber: 3, ownerPID: 102, ownerName: "Firefox", title: "Mozilla", bundleIdentifier: "org.mozilla.Firefox")
        ]
        let results = FuzzySearch.search(query: "safari", in: windows)
        
        #expect(results.count == 1)
        #expect(results.first?.ownerName == "Safari")
    }
    
    @Test func searchMatchesOwnerName() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Google Chrome", title: "", bundleIdentifier: "com.google.Chrome")
        ]
        let results = FuzzySearch.search(query: "google", in: windows)
        #expect(results.count == 1)
        #expect(results.first?.ownerName == "Google Chrome")
    }
    
    @Test func prefixMatchHigherScoreThanPartialMatch() {
        let prefixScore = FuzzySearch.score(query: "saf", target: "Safari")
        let partialScore = FuzzySearch.score(query: "ari", target: "Safari")
        #expect(prefixScore > partialScore)
    }
    
    @Test func searchCombinesTitleAndOwnerScores() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Google Search", bundleIdentifier: "com.apple.Safari")
        ]
        let resultsByTitle = FuzzySearch.search(query: "google", in: windows)
        let resultsByOwner = FuzzySearch.search(query: "safari", in: windows)
        
        #expect(resultsByTitle.count == 1)
        #expect(resultsByOwner.count == 1)
    }
    
    @Test func emptyWindowsReturnsEmpty() {
        let results = FuzzySearch.search(query: "test", in: [])
        #expect(results.isEmpty)
    }
    
    @Test func searchIsCaseInsensitive() {
        let windows = [
            WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Test", bundleIdentifier: "com.apple.Safari")
        ]
        let results1 = FuzzySearch.search(query: "SAFARI", in: windows)
        let results2 = FuzzySearch.search(query: "test", in: windows)
        
        #expect(results1.count == 1)
        #expect(results2.count == 1)
    }
}

@Suite final class WindowInfoTests {
    
    @Test func displayTitleUsesTitleWhenAvailable() {
        let window = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "My Tab", bundleIdentifier: "com.apple.Safari")
        #expect(window.displayTitle == "My Tab")
    }
    
    @Test func displayTitleFallsBackToOwnerName() {
        let window = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "", bundleIdentifier: "com.apple.Safari")
        #expect(window.displayTitle == "Safari")
    }
    
    @Test func displayTitleFallsBackToOwnerNameWhenTitleIsWhitespace() {
        let window = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "   ", bundleIdentifier: "com.apple.Safari")
        #expect(window.displayTitle == "Safari")
    }
    
    @Test func equalityBasedOnWindowNumberAndPID() {
        let window1 = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab1", bundleIdentifier: "com.apple.Safari")
        let window2 = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab2", bundleIdentifier: "com.apple.Safari")
        let window3 = WindowInfo(windowNumber: 2, ownerPID: 100, ownerName: "Safari", title: "Tab1", bundleIdentifier: "com.apple.Safari")
        
        #expect(window1 == window2)
        #expect(window1 != window3)
    }
    
    @Test func windowInfoIsIdentifiable() {
        let window = WindowInfo(windowNumber: 1, ownerPID: 100, ownerName: "Safari", title: "Tab", bundleIdentifier: "com.apple.Safari")
        let _ = window.id
    }
}
