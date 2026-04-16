// StorageManager.swift
// NovaBrowser - Core data persistence coordinator

import Foundation

final class StorageManager {
    static let shared = StorageManager()

    private let documentsURL: URL
    private let cacheURL: URL

    private init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func initialize() {
        createDirectories()
    }

    func persistAll() {
        // Trigger all managers to save
        BookmarkManager.shared.objectWillChange.send()
        HistoryManager.shared.objectWillChange.send()
        DownloadManager.shared.objectWillChange.send()
    }

    // MARK: - Directories
    private func createDirectories() {
        let dirs = [
            documentsURL.appendingPathComponent("Downloads"),
            documentsURL.appendingPathComponent("Bookmarks"),
            cacheURL.appendingPathComponent("Favicons"),
            cacheURL.appendingPathComponent("Thumbnails"),
            cacheURL.appendingPathComponent("WebCache")
        ]

        for dir in dirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Cache Management
    func clearCache() {
        let cacheDir = cacheURL.appendingPathComponent("WebCache")
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func cacheSize() -> Int64 {
        let cacheDir = cacheURL.appendingPathComponent("WebCache")
        return directorySize(at: cacheDir)
    }

    func downloadsSize() -> Int64 {
        let downloadsDir = documentsURL.appendingPathComponent("Downloads")
        return directorySize(at: downloadsDir)
    }

    private func directorySize(at url: URL) -> Int64 {
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
        var size: Int64 = 0
        while let fileURL = enumerator?.nextObject() as? URL {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }

    // MARK: - Favicon Cache
    func cacheFavicon(_ data: Data, forHost host: String) {
        let faviconDir = cacheURL.appendingPathComponent("Favicons")
        let fileURL = faviconDir.appendingPathComponent(host.replacingOccurrences(of: "/", with: "_"))
        try? data.write(to: fileURL)
    }

    func getCachedFavicon(forHost host: String) -> Data? {
        let faviconDir = cacheURL.appendingPathComponent("Favicons")
        let fileURL = faviconDir.appendingPathComponent(host.replacingOccurrences(of: "/", with: "_"))
        return try? Data(contentsOf: fileURL)
    }

    // MARK: - Screenshot Cache
    func cacheScreenshot(_ data: Data, forTabId id: String) {
        let thumbDir = cacheURL.appendingPathComponent("Thumbnails")
        let fileURL = thumbDir.appendingPathComponent("\(id).jpg")
        try? data.write(to: fileURL)
    }

    func getCachedScreenshot(forTabId id: String) -> Data? {
        let thumbDir = cacheURL.appendingPathComponent("Thumbnails")
        let fileURL = thumbDir.appendingPathComponent("\(id).jpg")
        return try? Data(contentsOf: fileURL)
    }
}
