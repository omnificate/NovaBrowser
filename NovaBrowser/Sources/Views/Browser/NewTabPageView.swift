// NewTabPageView.swift
// NovaBrowser - Beautiful new tab page with favorites and search

import SwiftUI

struct NewTabPageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NewTabPageViewModel()
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)

                // Logo
                logoSection

                // Search bar
                searchSection

                // Quick links / Favorites
                if !viewModel.favorites.isEmpty {
                    quickLinksSection
                }

                // Frequently visited
                if !viewModel.frequentlyVisited.isEmpty {
                    frequentlyVisitedSection
                }

                // News / Reading list
                if !viewModel.readingList.isEmpty {
                    readingListSection
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("NovaBrowser")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if appState.isPrivateBrowsing {
                Label("Private Browsing", systemImage: "eye.slash.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search or enter website", text: $searchText, onCommit: {
                guard !searchText.isEmpty else { return }
                appState.navigateToAddressBarInput(searchText)
                searchText = ""
            })
            .focused($searchFocused)
            .font(.system(size: 16))
            .autocapitalization(.none)
            .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }

    // MARK: - Quick Links
    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Favorites")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(viewModel.favorites.prefix(8)) { bookmark in
                    QuickLinkCell(bookmark: bookmark) {
                        if let url = URL(string: bookmark.url) {
                            appState.openURL(url)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Frequently Visited
    private var frequentlyVisitedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Visited")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.frequentlyVisited.prefix(6)) { item in
                    FrequentSiteCard(item: item) {
                        if let url = URL(string: item.url) {
                            appState.openURL(url)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reading List
    private var readingListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading List")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(viewModel.readingList.prefix(5)) { bookmark in
                ReadingListRow(bookmark: bookmark) {
                    if let url = URL(string: bookmark.url) {
                        appState.openURL(url)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Link Cell
struct QuickLinkCell: View {
    let bookmark: Bookmark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    if let faviconData = bookmark.favicon,
                       let image = UIImage(data: faviconData) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(String(bookmark.title.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorForString(bookmark.url))
                            )
                    }
                }

                Text(bookmark.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
    }

    private func colorForString(_ string: String) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .red, .pink, .cyan, .indigo]
        let hash = abs(string.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Frequent Site Card
struct FrequentSiteCard: View {
    let item: HistoryItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let faviconData = item.favicon,
                       let image = UIImage(data: faviconData) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "globe")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                    }

                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Text(URLHelper.displayHost(for: item.url))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Reading List Row
struct ReadingListRow: View {
    let bookmark: Bookmark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(URLHelper.displayHost(for: bookmark.url))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - View Model
class NewTabPageViewModel: ObservableObject {
    @Published var favorites: [Bookmark] = []
    @Published var frequentlyVisited: [HistoryItem] = []
    @Published var readingList: [Bookmark] = []

    func loadData() {
        favorites = BookmarkManager.shared.getFavorites()
        frequentlyVisited = HistoryManager.shared.getFrequentlyVisited(limit: 6)
        readingList = BookmarkManager.shared.getReadingList()
    }
}
