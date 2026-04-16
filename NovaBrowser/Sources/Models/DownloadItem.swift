// DownloadItem.swift
// NovaBrowser - Download tracking model

import Foundation

enum DownloadStatus: String, Codable {
    case pending
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

struct DownloadItem: Codable, Identifiable, Hashable {
    let id: UUID
    var filename: String
    var url: String
    var mimeType: String
    var totalBytes: Int64
    var downloadedBytes: Int64
    var status: DownloadStatus
    var localPath: String?
    var dateStarted: Date
    var dateCompleted: Date?
    var errorMessage: String?

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(downloadedBytes) / Double(totalBytes)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var formattedDownloaded: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }

    init(filename: String, url: String, mimeType: String = "application/octet-stream") {
        self.id = UUID()
        self.filename = filename
        self.url = url
        self.mimeType = mimeType
        self.totalBytes = 0
        self.downloadedBytes = 0
        self.status = .pending
        self.dateStarted = Date()
    }
}

// MARK: - File Type Detection
extension DownloadItem {
    var fileExtension: String {
        (filename as NSString).pathExtension.lowercased()
    }

    var isImage: Bool {
        ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp", "ico", "tiff"].contains(fileExtension)
    }

    var isVideo: Bool {
        ["mp4", "mov", "avi", "mkv", "webm", "m4v", "flv"].contains(fileExtension)
    }

    var isAudio: Bool {
        ["mp3", "m4a", "wav", "flac", "aac", "ogg", "wma"].contains(fileExtension)
    }

    var isDocument: Bool {
        ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "csv"].contains(fileExtension)
    }

    var isArchive: Bool {
        ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "ipa"].contains(fileExtension)
    }

    var systemIconName: String {
        if isImage { return "photo" }
        if isVideo { return "film" }
        if isAudio { return "music.note" }
        if isDocument { return "doc.text" }
        if isArchive { return "archivebox" }
        return "doc"
    }
}
