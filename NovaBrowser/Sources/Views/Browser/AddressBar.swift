// AddressBar.swift
// NovaBrowser - Smart address bar with search suggestions

import SwiftUI

struct AddressBar: View {
    @ObservedObject var viewModel: AddressBarViewModel
    @EnvironmentObject var appState: AppState
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Security indicator
            securityIndicator

            // Text field
            ZStack(alignment: .leading) {
                if viewModel.text.isEmpty && !isFocused {
                    Text(placeholderText)
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                }

                TextField("", text: $viewModel.text, onCommit: {
                    submitAddress()
                })
                .focused($isFocused)
                .font(.system(size: 15))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.webSearch)
                .textContentType(.URL)
                .onChange(of: viewModel.text) { newValue in
                    viewModel.textDidChange(newValue)
                }
                .onChange(of: isFocused) { focused in
                    if focused {
                        viewModel.text = appState.activeTab?.currentURL?.absoluteString ?? ""
                        viewModel.selectAll()
                        appState.addressBarFocused = true
                    } else {
                        viewModel.showSuggestions = false
                        appState.addressBarFocused = false
                        updateDisplayText()
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Clear / Reload button
            if isFocused && !viewModel.text.isEmpty {
                Button(action: {
                    viewModel.text = ""
                    viewModel.suggestions = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            } else if let tab = appState.activeTab {
                Button(action: {
                    if tab.isLoading {
                        tab.stopLoading()
                    } else {
                        tab.reloadFromOrigin()
                    }
                }) {
                    Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
        .onAppear {
            updateDisplayText()
        }
    }

    private var placeholderText: String {
        "Search or enter address"
    }

    private var securityIndicator: some View {
        Group {
            if let tab = appState.activeTab, tab.currentURL != nil {
                if tab.isSecure {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                }
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
        }
    }

    private func submitAddress() {
        let input = viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        appState.navigateToAddressBarInput(input)
        isFocused = false
        viewModel.showSuggestions = false
    }

    private func updateDisplayText() {
        if let url = appState.activeTab?.currentURL {
            viewModel.text = URLHelper.displayString(for: url)
        } else {
            viewModel.text = ""
        }
    }
}

// MARK: - Address Bar View Model
class AddressBarViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var suggestions: [SearchSuggestion] = []
    @Published var showSuggestions: Bool = false

    private var debounceTimer: Timer?
    private let suggestionsService = SearchSuggestionsService()

    func textDidChange(_ newText: String) {
        debounceTimer?.invalidate()
        guard !newText.isEmpty else {
            suggestions = []
            showSuggestions = false
            return
        }

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.fetchSuggestions(for: newText)
        }
    }

    func selectSuggestion(_ text: String) {
        self.text = text
        showSuggestions = false
    }

    func selectAll() {
        // Text selection handled natively
    }

    private func fetchSuggestions(for query: String) {
        suggestionsService.fetchSuggestions(for: query) { [weak self] results in
            DispatchQueue.main.async {
                self?.suggestions = results
                self?.showSuggestions = !results.isEmpty
            }
        }
    }
}

// MARK: - Search Suggestion Model
struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: SuggestionType

    enum SuggestionType {
        case search
        case url
        case history
        case bookmark
    }

    var iconName: String {
        switch type {
        case .search: return "magnifyingglass"
        case .url: return "globe"
        case .history: return "clock"
        case .bookmark: return "bookmark"
        }
    }
}

// MARK: - Suggestions Overlay
struct SuggestionsOverlay: View {
    let suggestions: [SearchSuggestion]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.prefix(8)) { suggestion in
                Button(action: { onSelect(suggestion.text) }) {
                    HStack(spacing: 12) {
                        Image(systemName: suggestion.iconName)
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                            .frame(width: 24)

                        Text(suggestion.text)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if suggestion.id != suggestions.prefix(8).last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
