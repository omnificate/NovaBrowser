// BookmarkManager.swift
// NovaBrowser - Bookmark persistence and management

import SwiftUI
import Combine

final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published var allBookmarks: [Bookmark] = []
    @Published var folders: [BookmarkFolder] = []

    private let bookmarksKey = "nova_bookmarks"
    private let foldersKey = "nova_bookmark_folders"

    private init() {
        loadBookmarks()
        loadFolders()
        ensureDefaultFolders()
    }

    // MARK: - Bookmark CRUD
    func addBookmark(title: String, url: String, favicon: Data? = nil, folderId: UUID? = nil) {
        let bookmark = Bookmark(
            title: title,
            url: url,
            favicon: favicon,
            parentFolderId: folderId,
            position: allBookmarks.count
        )
        allBookmarks.append(bookmark)
        saveBookmarks()
    }

    func updateBookmark(_ id: UUID, title: String? = nil, url: String? = nil, folderId: UUID? = nil) {
        guard let index = allBookmarks.firstIndex(where: { $0.id == id }) else { return }
        if let title = title { allBookmarks[index].title = title }
        if let url = url { allBookmarks[index].url = url }
        if let folderId = folderId { allBookmarks[index].parentFolderId = folderId }
        allBookmarks[index].dateModified = Date()
        saveBookmarks()
    }

    func deleteBookmark(_ id: UUID) {
        allBookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }

    func isBookmarked(url: String) -> Bool {
        allBookmarks.contains { $0.url == url }
    }

    func toggleBookmark(title: String, url: String) {
        if let existing = allBookmarks.first(where: { $0.url == url }) {
            deleteBookmark(existing.id)
        } else {
            addBookmark(title: title, url: url)
        }
    }

    // MARK: - Folder CRUD
    func addFolder(name: String, parentId: UUID? = nil) {
        let folder = BookmarkFolder(name: name, parentFolderId: parentId, position: folders.count)
        folders.append(folder)
        saveFolders()
    }

    func deleteFolder(_ id: UUID) {
        // Delete all bookmarks in folder
        allBookmarks.removeAll { $0.parentFolderId == id }
        // Delete sub-folders
        let subFolders = folders.filter { $0.parentFolderId == id }
        for sub in subFolders {
            deleteFolder(sub.id)
        }
        folders.removeAll { $0.id == id }
        saveFolders()
        saveBookmarks()
    }

    // MARK: - Queries
    func bookmarksInFolder(_ folderId: UUID?) -> [Bookmark] {
        allBookmarks.filter { $0.parentFolderId == folderId }
            .sorted { $0.position < $1.position }
    }

    func getFavorites() -> [Bookmark] {
        allBookmarks.filter { $0.parentFolderId == nil }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    func getReadingList() -> [Bookmark] {
        allBookmarks.filter { $0.parentFolderId == BookmarkFolder.readingListId }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    func addToReadingList(title: String, url: String) {
        addBookmark(title: title, url: url, folderId: BookmarkFolder.readingListId)
    }

    // MARK: - Persistence
    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(allBookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        allBookmarks = bookmarks
    }

    private func saveFolders() {
        if let data = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(data, forKey: foldersKey)
        }
    }

    private func loadFolders() {
        guard let data = UserDefaults.standard.data(forKey: foldersKey),
              let decoded = try? JSONDecoder().decode([BookmarkFolder].self, from: data) else { return }
        folders = decoded
    }

    private func ensureDefaultFolders() {
        if !folders.contains(where: { $0.name == "Favorites" }) {
            folders.insert(BookmarkFolder(name: "Favorites"), at: 0)
        }
        if !folders.contains(where: { $0.name == "Reading List" }) {
            folders.append(BookmarkFolder(name: "Reading List"))
        }
        saveFolders()
    }
}
