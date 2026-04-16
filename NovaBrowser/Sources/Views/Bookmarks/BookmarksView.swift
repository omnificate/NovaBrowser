// BookmarksView.swift
// NovaBrowser - Bookmarks manager with folders

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var showAddBookmark = false
    @State private var showAddFolder = false
    @State private var currentFolder: UUID? = nil

    var body: some View {
        NavigationView {
            List {
                // Folders
                if currentFolder == nil {
                    Section(header: Text("Folders")) {
                        ForEach(bookmarkManager.folders) { folder in
                            Button(action: { currentFolder = folder.id }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(folder.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(bookmarkManager.bookmarksInFolder(folder.id).count)")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                bookmarkManager.deleteFolder(bookmarkManager.folders[index].id)
                            }
                        }
                    }
                }

                // Bookmarks
                Section(header: Text(currentFolder != nil ? "Bookmarks" : "All Bookmarks")) {
                    ForEach(filteredBookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark) {
                            if let url = URL(string: bookmark.url) {
                                appState.openURL(url)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .onDelete { indices in
                        let toDelete = filteredBookmarks
                        for index in indices {
                            bookmarkManager.deleteBookmark(toDelete[index].id)
                        }
                    }
                    .onMove { source, destination in
                        // Reorder
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .searchable(text: $searchText, prompt: "Search bookmarks")
            .navigationTitle(currentFolder != nil ? folderName : "Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentFolder != nil {
                        Button(action: { currentFolder = nil }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    } else {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Button(action: { showAddBookmark = true }) {
                                Label("Add Bookmark", systemImage: "bookmark")
                            }
                            Button(action: { showAddFolder = true }) {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .sheet(isPresented: $showAddBookmark) {
                AddBookmarkView(folderId: currentFolder)
            }
            .sheet(isPresented: $showAddFolder) {
                AddFolderView()
            }
        }
    }

    private var filteredBookmarks: [Bookmark] {
        let bookmarks = currentFolder != nil ?
            bookmarkManager.bookmarksInFolder(currentFolder!) :
            bookmarkManager.allBookmarks

        if searchText.isEmpty {
            return bookmarks
        }
        return bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var folderName: String {
        if let id = currentFolder {
            return bookmarkManager.folders.first(where: { $0.id == id })?.name ?? "Bookmarks"
        }
        return "Bookmarks"
    }
}

// MARK: - Bookmark Row
struct BookmarkRow: View {
    let bookmark: Bookmark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let faviconData = bookmark.favicon,
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
                    Text(bookmark.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(URLHelper.displayHost(for: bookmark.url))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Add Bookmark View
struct AddBookmarkView: View {
    let folderId: UUID?
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var url = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bookmark Details")) {
                    TextField("Title", text: $title)
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        BookmarkManager.shared.addBookmark(
                            title: title,
                            url: url,
                            folderId: folderId
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || url.isEmpty)
                }
            }
            .onAppear {
                if let tab = AppState.shared.activeTab {
                    title = tab.title
                    url = tab.currentURL?.absoluteString ?? ""
                }
            }
        }
    }
}

// MARK: - Add Folder View
struct AddFolderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Folder Name")) {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        BookmarkManager.shared.addFolder(name: name)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
