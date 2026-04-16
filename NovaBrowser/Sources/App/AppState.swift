// AppState.swift
// NovaBrowser - Central application state management

import SwiftUI
import WebKit
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published State
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabIndex: Int = 0
    @Published var isShowingTabs: Bool = false
    @Published var isShowingSettings: Bool = false
    @Published var isShowingBookmarks: Bool = false
    @Published var isShowingHistory: Bool = false
    @Published var isShowingDownloads: Bool = false
    @Published var isPrivateBrowsing: Bool = false
    @Published var isShowingFindInPage: Bool = false
    @Published var isShowingShareSheet: Bool = false
    @Published var isFullScreen: Bool = false
    @Published var searchText: String = ""
    @Published var addressBarFocused: Bool = false

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let stateKey = "nova_browser_state"

    var activeTab: BrowserTab? {
        guard tabs.indices.contains(activeTabIndex) else { return nil }
        return tabs[activeTabIndex]
    }

    private init() {
        restoreState()
        if tabs.isEmpty {
            createNewTab()
        }
    }

    // MARK: - Tab Management
    func createNewTab(url: URL? = nil, switchTo: Bool = true) {
        let tab = BrowserTab(
            url: url,
            isPrivate: isPrivateBrowsing
        )
        tabs.append(tab)
        if switchTo {
            activeTabIndex = tabs.count - 1
        }
    }

    func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        let tab = tabs[index]
        tab.cleanup()
        tabs.remove(at: index)

        if tabs.isEmpty {
            createNewTab()
        } else if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        }
    }

    func closeAllTabs() {
        tabs.forEach { $0.cleanup() }
        tabs.removeAll()
        createNewTab()
    }

    func switchToTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        activeTabIndex = index
        isShowingTabs = false
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
        // Adjust active index
        if let first = source.first {
            if first == activeTabIndex {
                activeTabIndex = destination > first ? destination - 1 : destination
            } else if first < activeTabIndex && destination > activeTabIndex {
                activeTabIndex -= 1
            } else if first > activeTabIndex && destination <= activeTabIndex {
                activeTabIndex += 1
            }
        }
    }

    func duplicateTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        let original = tabs[index]
        createNewTab(url: original.currentURL)
    }

    // MARK: - Navigation
    func openURL(_ url: URL) {
        if let tab = activeTab {
            tab.loadURL(url)
        } else {
            createNewTab(url: url)
        }
    }

    func navigateToAddressBarInput(_ input: String) {
        let url = URLHelper.resolveInput(input)
        openURL(url)
        addressBarFocused = false
    }

    // MARK: - State Persistence
    func saveState() {
        guard !isPrivateBrowsing else { return }

        let tabData = tabs.filter { !$0.isPrivate }.map { tab -> [String: Any] in
            var data: [String: Any] = [:]
            data["url"] = tab.currentURL?.absoluteString ?? ""
            data["title"] = tab.title
            return data
        }

        let state: [String: Any] = [
            "tabs": tabData,
            "activeIndex": activeTabIndex,
            "timestamp": Date().timeIntervalSince1970
        ]

        UserDefaults.standard.set(state, forKey: stateKey)
    }

    func restoreState() {
        guard let state = UserDefaults.standard.dictionary(forKey: stateKey),
              let tabData = state["tabs"] as? [[String: Any]] else { return }

        for data in tabData {
            if let urlString = data["url"] as? String,
               let url = URL(string: urlString), !urlString.isEmpty {
                let tab = BrowserTab(url: url, isPrivate: false)
                tab.title = data["title"] as? String ?? ""
                tabs.append(tab)
            }
        }

        if let index = state["activeIndex"] as? Int, tabs.indices.contains(index) {
            activeTabIndex = index
        }
    }

    func resumeFromBackground() {
        // Refresh active tab if stale
        if let tab = activeTab, let url = tab.currentURL {
            let staleThreshold: TimeInterval = 30 * 60 // 30 minutes
            if Date().timeIntervalSince(tab.lastAccessTime) > staleThreshold {
                tab.reload()
            }
        }
    }

    // MARK: - Private Browsing
    func togglePrivateBrowsing() {
        isPrivateBrowsing.toggle()
        if isPrivateBrowsing {
            // Store current tabs
            saveState()
            // Clear and create incognito tab
            let privateTabs = tabs.filter { $0.isPrivate }
            if privateTabs.isEmpty {
                createNewTab()
            }
        }
    }

    func clearPrivateData() {
        tabs.filter { $0.isPrivate }.forEach { $0.cleanup() }
        tabs.removeAll { $0.isPrivate }

        // Clear cookies and cache for private session
        let dataStore = WKWebsiteDataStore.nonPersistent()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                               for: records) { }
        }
    }
}
