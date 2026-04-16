// HistoryItem.swift
// NovaBrowser - Browsing history data model

import Foundation

struct HistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var visitDate: Date
    var visitCount: Int
    var favicon: Data?

    init(title: String, url: String, favicon: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.visitDate = Date()
        self.visitCount = 1
        self.favicon = favicon
    }
}

// MARK: - History Section (for grouped display)
struct HistorySection: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    var items: [HistoryItem]
}

// MARK: - Searchable
extension HistoryItem {
    func matches(query: String) -> Bool {
        let q = query.lowercased()
        return title.lowercased().contains(q) || url.lowercased().contains(q)
    }
}
