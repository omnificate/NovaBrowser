// DownloadManager.swift
// NovaBrowser - File download management

import SwiftUI
import Combine

final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [DownloadItem] = []

    private var activeTasks: [UUID: URLSessionDownloadTask] = [:]
    private var session: URLSession!
    private let storageKey = "nova_downloads"

    private let downloadableTypes: Set<String> = [
        "application/zip", "application/x-zip-compressed", "application/gzip",
        "application/x-tar", "application/x-rar-compressed", "application/x-7z-compressed",
        "application/pdf", "application/msword", "application/x-apple-diskimage",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "application/octet-stream", "application/x-bzip2",
        "audio/mpeg", "audio/mp4", "audio/x-m4a", "audio/wav", "audio/flac",
        "video/mp4", "video/quicktime", "video/x-msvideo", "video/x-matroska",
        "image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml",
        "application/x-ipa"
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        loadDownloads()
    }

    // MARK: - Download Actions
    func startDownload(url: URL, suggestedFilename: String? = nil) {
        let filename = suggestedFilename ?? url.lastPathComponent
        var item = DownloadItem(filename: filename, url: url.absoluteString)
        item.status = .downloading

        downloads.insert(item, at: 0)
        saveDownloads()

        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                self?.handleDownloadCompletion(
                    itemId: item.id,
                    tempURL: tempURL,
                    response: response,
                    error: error
                )
            }
        }

        // Observe progress
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                if let index = self?.downloads.firstIndex(where: { $0.id == item.id }) {
                    self?.downloads[index].downloadedBytes = Int64(progress.fractionCompleted * Double(self?.downloads[index].totalBytes ?? 0))
                }
            }
        }
        _ = observation // Keep reference

        activeTasks[item.id] = task
        task.resume()
    }

    func pauseDownload(_ id: UUID) {
        activeTasks[id]?.cancel(byProducingResumeData: { _ in })
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .paused
            saveDownloads()
        }
    }

    func resumeDownload(_ id: UUID) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        let item = downloads[index]

        if let url = URL(string: item.url) {
            downloads[index].status = .downloading
            let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
                DispatchQueue.main.async {
                    self?.handleDownloadCompletion(itemId: id, tempURL: tempURL, response: response, error: error)
                }
            }
            activeTasks[id] = task
            task.resume()
        }
    }

    func cancelDownload(_ id: UUID) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .cancelled
            saveDownloads()
        }
    }

    func clearCompleted() {
        downloads.removeAll { $0.status == .completed || $0.status == .cancelled || $0.status == .failed }
        saveDownloads()
    }

    func resumePendingDownloads() {
        // Mark any downloading items as failed on app restart
        for i in downloads.indices {
            if downloads[i].status == .downloading {
                downloads[i].status = .failed
                downloads[i].errorMessage = "Download interrupted"
            }
        }
        saveDownloads()
    }

    // MARK: - Type Checking
    func shouldDownload(mimeType: String) -> Bool {
        downloadableTypes.contains(mimeType.lowercased())
    }

    // MARK: - Private
    private func handleDownloadCompletion(itemId: UUID, tempURL: URL?, response: URLResponse?, error: Error?) {
        guard let index = downloads.firstIndex(where: { $0.id == itemId }) else { return }

        if let error = error {
            downloads[index].status = .failed
            downloads[index].errorMessage = error.localizedDescription
            saveDownloads()
            return
        }

        guard let tempURL = tempURL else {
            downloads[index].status = .failed
            downloads[index].errorMessage = "No file received"
            saveDownloads()
            return
        }

        // Move to documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDir = documentsPath.appendingPathComponent("Downloads", isDirectory: true)

        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)

        var destURL = downloadsDir.appendingPathComponent(downloads[index].filename)

        // Handle duplicate filenames
        var counter = 1
        while FileManager.default.fileExists(atPath: destURL.path) {
            let name = (downloads[index].filename as NSString).deletingPathExtension
            let ext = (downloads[index].filename as NSString).pathExtension
            destURL = downloadsDir.appendingPathComponent("\(name) (\(counter)).\(ext)")
            counter += 1
        }

        do {
            try FileManager.default.moveItem(at: tempURL, to: destURL)
            downloads[index].localPath = destURL.path
            downloads[index].status = .completed
            downloads[index].dateCompleted = Date()

            if let attrs = try? FileManager.default.attributesOfItem(atPath: destURL.path),
               let size = attrs[.size] as? Int64 {
                downloads[index].totalBytes = size
                downloads[index].downloadedBytes = size
            }
        } catch {
            downloads[index].status = .failed
            downloads[index].errorMessage = error.localizedDescription
        }

        activeTasks[itemId] = nil
        saveDownloads()
    }

    // MARK: - Persistence
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadDownloads() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DownloadItem].self, from: data) else { return }
        downloads = decoded
    }
}
