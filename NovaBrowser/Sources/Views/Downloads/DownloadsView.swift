// DownloadsView.swift
// NovaBrowser - Download manager UI

import SwiftUI

struct DownloadsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if downloadManager.downloads.isEmpty {
                    emptyState
                } else {
                    downloadList
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !downloadManager.downloads.isEmpty {
                        Button("Clear") {
                            showClearConfirmation = true
                        }
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
                    title: Text("Clear Downloads"),
                    message: Text("Remove all completed downloads from the list?"),
                    primaryButton: .destructive(Text("Clear")) {
                        downloadManager.clearCompleted()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var downloadList: some View {
        List {
            // Active downloads
            let active = downloadManager.downloads.filter { $0.status == .downloading || $0.status == .pending }
            if !active.isEmpty {
                Section(header: Text("Active")) {
                    ForEach(active) { item in
                        DownloadRow(item: item)
                    }
                }
            }

            // Paused
            let paused = downloadManager.downloads.filter { $0.status == .paused }
            if !paused.isEmpty {
                Section(header: Text("Paused")) {
                    ForEach(paused) { item in
                        DownloadRow(item: item)
                    }
                }
            }

            // Completed
            let completed = downloadManager.downloads.filter { $0.status == .completed }
            if !completed.isEmpty {
                Section(header: Text("Completed")) {
                    ForEach(completed) { item in
                        DownloadRow(item: item)
                    }
                }
            }

            // Failed
            let failed = downloadManager.downloads.filter { $0.status == .failed }
            if !failed.isEmpty {
                Section(header: Text("Failed")) {
                    ForEach(failed) { item in
                        DownloadRow(item: item)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Downloads")
                .font(.title2.weight(.semibold))

            Text("Files you download will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Download Row
struct DownloadRow: View {
    let item: DownloadItem

    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: item.systemIconName)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                if item.status == .downloading {
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text("\(item.formattedDownloaded) of \(item.formattedSize)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if item.status == .completed {
                    Text("\(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if item.status == .failed {
                    Text(item.errorMessage ?? "Download failed")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if item.status == .paused {
                    Text("Paused - \(item.formattedDownloaded) of \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Action button
            actionButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch item.status {
        case .downloading:
            Button(action: { DownloadManager.shared.pauseDownload(item.id) }) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            .buttonStyle(PlainButtonStyle())

        case .paused:
            Button(action: { DownloadManager.shared.resumeDownload(item.id) }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())

        case .failed:
            Button(action: {
                if let url = URL(string: item.url) {
                    DownloadManager.shared.startDownload(url: url, suggestedFilename: item.filename)
                }
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())

        case .completed:
            Button(action: { shareFile(item) }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())

        default:
            ProgressView()
        }
    }

    private func shareFile(_ item: DownloadItem) {
        guard let path = item.localPath else { return }
        let url = URL(fileURLWithPath: path)
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(ac, animated: true)
        }
    }
}
