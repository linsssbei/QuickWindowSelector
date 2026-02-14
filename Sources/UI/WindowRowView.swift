import SwiftUI
import AppKit

struct WindowRowView: View {
    let window: WindowInfo
    let isSelected: Bool
    let searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            appIcon
            
            VStack(alignment: .leading, spacing: 2) {
                // Show window title if available, otherwise app name
                if !window.title.isEmpty {
                    highlightedText(searchText, in: truncateTitle(window.title))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Show app name as subtitle
                    Text(window.ownerName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    highlightedText(searchText, in: window.ownerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
    
    private func truncateTitle(_ title: String) -> String {
        if title.count > 50 {
            return String(title.prefix(47)) + "..."
        }
        return title
    }
    
    private var appIcon: some View {
        Group {
            if let bundleId = window.bundleIdentifier,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == window.ownerName || $0.bundleIdentifier == window.bundleIdentifier }) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    defaultIcon
                }
            } else {
                defaultIcon
            }
        }
        .frame(width: 32, height: 32)
        .cornerRadius(6)
    }
    
    private var defaultIcon: some View {
        Image(systemName: "app.fill")
            .font(.system(size: 20))
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var highlightedTitle: some View {
        if searchText.isEmpty {
            Text(window.displayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        } else {
            highlightedText(searchText, in: window.displayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    private func highlightedText(_ query: String, in text: String) -> Text {
        guard !query.isEmpty else { return Text(text) }
        
        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()
        
        var result = Text("")
        var currentIndex = text.startIndex
        
        var searchStartIndex = lowercasedText.startIndex
        while let range = lowercasedText.range(of: lowercasedQuery, range: searchStartIndex..<lowercasedText.endIndex) {
            let textStart = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound))
            let textEnd = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound))
            
            result = result + Text(String(text[currentIndex..<textStart]))
                .foregroundColor(.secondary)
            result = result + Text(String(text[textStart..<textEnd]))
                .foregroundColor(.accentColor)
                .fontWeight(.bold)
            
            currentIndex = textEnd
            searchStartIndex = range.upperBound
        }
        
        result = result + Text(String(text[currentIndex...]))
            .foregroundColor(.secondary)
        
        return result
    }
}
