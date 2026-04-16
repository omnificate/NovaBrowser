// HistoryManager.swift
// NovaBrowser - Browsing history persistence

import SwiftUI
import Combine

final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var items: [HistoryItem] = []
    @Published var sections: [HistorySection] = []

    private let storageKey = "nova_history"
    private let maxHistoryItems = 5000

    private init() {
        loadHistory()
        buildSections()
    }

    // MARK: - Add to History
    func addToHistory(title: String, url: String, favicon: Data? = nil) {
        // Don't record empty or about: URLs
        guard !url.isEmpty, !url.hasPrefix("about:") else { return }

        // Update existing or create new
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index].visitCount += 1
            items[index].visitDate = Date()
            items[index].title = title
            if let favicon = favicon {
                items[index].favicon = favicon
            }
            // Move to front
            let item = items.remove(at: index)
            items.insert(item, at: 0)
        } else {
            let item = HistoryItem(title: title, url: url, favicon: favicon)
            items.insert(item, at: 0)
        }

        // Trim
        if items.count > maxHistoryItems {
            items = Array(items.prefix(maxHistoryItems))
        }

        saveHistory()
        buildSections()
    }

    // MARK: - Queries
    func getFrequentlyVisited(limit: Int = 10) -> [HistoryItem] {
        Array(items.sorted { $0.visitCount > $1.visitCount }.prefix(limit))
    }

    func getRecentHistory(limit: Int = 50) -> [HistoryItem] {
        Array(items.prefix(limit))
    }

    func search(query: String) -> [HistoryItem] {
        items.filter { $0.matches(query: query) }
    }

    // MARK: - Delete
    func deleteItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        saveHistory()
        buildSections()
    }

    func clearAll() {
        items.removeAll()
        sections.removeAll()
        saveHistory()
    }

    func clearLast(hours: Int) {
        let cutoff = Date().addingTimeInterval(-TimeInterval(hours * 3600))
        items.removeAll { $0.visitDate > cutoff }
        saveHistory()
        buildSections()
    }

    // MARK: - Sections
    private func buildSections() {
        let calendar = Calendar.current
        var sectionDict: [String: (date: Date, items: [HistoryItem])] = [:]

        for item in items {
            let key: String
            let date = item.visitDate

            if calendar.isDateInToday(date) {
                key = "Today"
            } else if calendar.isDateInYesterday(date) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                key = formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                key = formatter.string(from: date)
            }

            if sectionDict[key] != nil {
                sectionDict[key]?.items.append(item)
            } else {
                sectionDict[key] = (date: date, items: [item])
            }
        }

        sections = sectionDict.map { key, value in
            HistorySection(title: key, date: value.date, items: value.items)
        }
        .sorted { $0.date > $1.date }
    }

    // MARK: - Persistence
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return }
        items = decoded
    }
}
