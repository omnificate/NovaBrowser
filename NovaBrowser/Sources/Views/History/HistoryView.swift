// HistoryView.swift
// NovaBrowser - Browsing history with sections and search

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var historyManager = HistoryManager.shared
    @State private var searchText = ""
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if historyManager.sections.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showClearConfirmation = true }) {
                        Text("Clear")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showClearConfirmation) {
                Alert(
                    title: Text("Clear History"),
                    message: Text("This will remove all browsing history. This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear All")) {
                        historyManager.clearAll()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var historyList: some View {
        List {
            ForEach(filteredSections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.items) { item in
                        HistoryRow(item: item) {
                            if let url = URL(string: item.url) {
                                appState.openURL(url)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .onDelete { indices in
                        for index in indices {
                            historyManager.deleteItem(section.items[index].id)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $searchText, prompt: "Search history")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No History")
                .font(.title2.weight(.semibold))

            Text("Websites you visit will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var filteredSections: [HistorySection] {
        if searchText.isEmpty {
            return historyManager.sections
        }
        return historyManager.sections.compactMap { section in
            let filtered = section.items.filter { $0.matches(query: searchText) }
            return filtered.isEmpty ? nil : HistorySection(title: section.title, date: section.date, items: filtered)
        }
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let item: HistoryItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let faviconData = item.favicon,
                   let image = UIImage(data: faviconData) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Image(systemName: "globe")
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(URLHelper.displayHost(for: item.url))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(timeString(for: item.visitDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}
