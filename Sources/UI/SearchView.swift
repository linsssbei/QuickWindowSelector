import SwiftUI
import AppKit

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            searchField
            
            if viewModel.filteredWindows.isEmpty && !viewModel.searchText.isEmpty {
                noResultsView
            } else if !viewModel.filteredWindows.isEmpty {
                Divider()
                resultsList
            }
        }
        .frame(width: 600)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 18, weight: .medium))
            
            TextField("Search windows...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 20))
                .focused($isSearchFocused)
                .onExitCommand(perform: {
                    viewModel.onEscape?()
                })
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<viewModel.filteredWindows.count, id: \.self) { index in
                    let window = viewModel.filteredWindows[index]
                    WindowRowView(
                        window: window,
                        isSelected: index == viewModel.selectedIndex,
                        searchText: viewModel.searchText
                    )
                    .onTapGesture {
                        viewModel.selectedIndex = index
                        viewModel.confirmSelection()
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 300)
    }
    
    private var noResultsView: some View {
        HStack {
            Spacer()
            Text("No matching windows")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
                .padding()
            Spacer()
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
