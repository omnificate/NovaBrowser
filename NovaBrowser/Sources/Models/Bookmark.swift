// Bookmark.swift
// NovaBrowser - Bookmark and folder data models

import Foundation

struct Bookmark: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var favicon: Data?
    var parentFolderId: UUID?
    var position: Int
    var dateAdded: Date
    var dateModified: Date

    init(title: String, url: String, favicon: Data? = nil, parentFolderId: UUID? = nil, position: Int = 0) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.favicon = favicon
        self.parentFolderId = parentFolderId
        self.position = position
        self.dateAdded = Date()
        self.dateModified = Date()
    }
}

struct BookmarkFolder: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var parentFolderId: UUID?
    var position: Int
    var dateCreated: Date

    init(name: String, parentFolderId: UUID? = nil, position: Int = 0) {
        self.id = UUID()
        self.name = name
        self.parentFolderId = parentFolderId
        self.position = position
        self.dateCreated = Date()
    }
}

// MARK: - Special Folders
extension BookmarkFolder {
    static let favoritesId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let readingListId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static var favorites: BookmarkFolder {
        BookmarkFolder(name: "Favorites", parentFolderId: nil, position: 0)
    }
}
