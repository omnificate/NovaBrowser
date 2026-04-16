// SettingsView.swift
// NovaBrowser - Comprehensive settings panel

import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                // General
                generalSection

                // Search
                searchSection

                // Privacy & Security
                privacySection

                // Content
                contentSection

                // Appearance
                appearanceSection

                // Performance
                performanceSection

                // Data Management
                dataSection

                // About
                aboutSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    // MARK: - General Section
    private var generalSection: some View {
        Section(header: Text("General")) {
            // Search engine picker
            NavigationLink {
                SearchEnginePicker(selected: $settings.searchEngine)
            } label: {
                HStack {
                    Label("Search Engine", systemImage: "magnifyingglass")
                    Spacer()
                    Text(settings.searchEngine.displayName)
                        .foregroundColor(.secondary)
                }
            }

            // Home page
            NavigationLink {
                HomePageSettings(homeURL: $settings.homePageURL)
            } label: {
                Label("Home Page", systemImage: "house")
            }

            Toggle(isOn: $settings.openLinksInNewTab) {
                Label("Open Links in New Tab", systemImage: "square.stack")
            }

            Toggle(isOn: $settings.showSearchSuggestions) {
                Label("Search Suggestions", systemImage: "text.bubble")
            }
        }
    }

    // MARK: - Search Section
    private var searchSection: some View {
        Section(header: Text("Search")) {
            Toggle(isOn: $settings.showSearchSuggestions) {
                Label("Show Suggestions", systemImage: "sparkles")
            }

            Toggle(isOn: $settings.quickWebsiteSearch) {
                Label("Quick Website Search", systemImage: "bolt")
            }

            Toggle(isOn: $settings.preloadTopHit) {
                Label("Preload Top Hit", systemImage: "arrow.up.circle")
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        Section(header: Text("Privacy & Security")) {
            Toggle(isOn: $settings.adBlockingEnabled) {
                Label("Block Ads & Trackers", systemImage: "shield.checkered")
            }

            Toggle(isOn: $settings.blockPopups) {
                Label("Block Pop-ups", systemImage: "xmark.rectangle")
            }

            Toggle(isOn: $settings.doNotTrack) {
                Label("Send Do Not Track", systemImage: "hand.raised")
            }

            Toggle(isOn: $settings.blockCookies) {
                Label("Block Third-Party Cookies", systemImage: "circle.slash")
            }

            Toggle(isOn: $settings.httpsUpgrade) {
                Label("HTTPS Upgrade", systemImage: "lock.shield")
            }

            Toggle(isOn: $settings.fraudulentWebsiteWarning) {
                Label("Fraudulent Website Warning", systemImage: "exclamationmark.shield")
            }

            NavigationLink {
                ContentBlockerListView()
            } label: {
                Label("Content Blockers", systemImage: "list.bullet.rectangle")
            }
        }
    }

    // MARK: - Content Section
    private var contentSection: some View {
        Section(header: Text("Content")) {
            Toggle(isOn: $settings.enableJavaScript) {
                Label("JavaScript", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            Toggle(isOn: $settings.enableImages) {
                Label("Load Images", systemImage: "photo")
            }

            Toggle(isOn: $settings.autoplayVideos) {
                Label("Autoplay Videos", systemImage: "play.rectangle")
            }

            NavigationLink {
                FontSizeSettings(fontSize: $settings.pageFontSize)
            } label: {
                HStack {
                    Label("Font Size", systemImage: "textformat.size")
                    Spacer()
                    Text("\(Int(settings.pageFontSize))%")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $themeManager.selectedTheme) {
                Text("System").tag(AppTheme.system)
                Text("Light").tag(AppTheme.light)
                Text("Dark").tag(AppTheme.dark)
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle(isOn: $themeManager.forceDarkMode) {
                Label("Force Dark Mode on Pages", systemImage: "moon.fill")
            }

            // Accent color selection
            HStack {
                Text("Accent Color")
                Spacer()
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 24, height: 24)
            }
        }
    }

    // MARK: - Performance Section
    private var performanceSection: some View {
        Section(header: Text("Performance")) {
            Toggle(isOn: $settings.enablePrefetch) {
                Label("Link Prefetching", systemImage: "arrow.triangle.branch")
            }

            Toggle(isOn: $settings.hardwareAcceleration) {
                Label("Hardware Acceleration", systemImage: "cpu")
            }

            Toggle(isOn: $settings.compressData) {
                Label("Data Compression", systemImage: "arrow.down.doc")
            }

            Picker("Cache Size", selection: $settings.cacheSizeLimit) {
                Text("50 MB").tag(50)
                Text("100 MB").tag(100)
                Text("200 MB").tag(200)
                Text("500 MB").tag(500)
            }
        }
    }

    // MARK: - Data Section
    private var dataSection: some View {
        Section(header: Text("Data Management")) {
            Button(action: { clearBrowsingData() }) {
                Label("Clear Browsing Data", systemImage: "trash")
                    .foregroundColor(.red)
            }

            Button(action: { clearCache() }) {
                Label("Clear Cache", systemImage: "internaldrive")
                    .foregroundColor(.orange)
            }

            Button(action: { clearCookies() }) {
                Label("Clear Cookies", systemImage: "circle.slash")
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Engine")
                Spacer()
                Text("WebKit (CyberKit Enhanced)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            HStack {
                Text("Build")
                Spacer()
                Text("2026.04.16")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://github.com/user/NovaBrowser")!) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }

    // MARK: - Actions
    private func clearBrowsingData() {
        HistoryManager.shared.clearAll()
        clearCache()
        clearCookies()
    }

    private func clearCache() {
        let dataTypes: Set<String> = [
            WKWebsiteDataStore.allWebsiteDataTypes().joined()
        ]
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { }
    }

    private func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        WKWebsiteDataStore.default().removeData(
            ofTypes: [WKWebsiteDataTypeCookies],
            modifiedSince: .distantPast
        ) { }
    }
}

// MARK: - Sub-Settings Views

struct SearchEnginePicker: View {
    @Binding var selected: SearchEngine

    var body: some View {
        List {
            ForEach(SearchEngine.allCases) { engine in
                Button(action: { selected = engine }) {
                    HStack {
                        Image(systemName: engine.iconName)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)

                        Text(engine.displayName)
                            .foregroundColor(.primary)

                        Spacer()

                        if selected == engine {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search Engine")
    }
}

struct HomePageSettings: View {
    @Binding var homeURL: String

    var body: some View {
        List {
            Section(header: Text("Custom Home Page URL")) {
                TextField("https://", text: $homeURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }

            Section {
                Button("Use New Tab Page") { homeURL = "" }
                Button("Use Current Page") {
                    if let url = AppState.shared.activeTab?.currentURL {
                        homeURL = url.absoluteString
                    }
                }
            }
        }
        .navigationTitle("Home Page")
    }
}

struct FontSizeSettings: View {
    @Binding var fontSize: Double

    var body: some View {
        VStack(spacing: 20) {
            Text("Page Font Size: \(Int(fontSize))%")
                .font(.headline)

            Slider(value: $fontSize, in: 50...200, step: 10)
                .padding(.horizontal)

            HStack {
                Text("A").font(.caption)
                Spacer()
                Text("A").font(.title)
            }
            .padding(.horizontal, 40)

            Text("Preview text at \(Int(fontSize))% size")
                .font(.system(size: 16 * CGFloat(fontSize / 100)))
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Font Size")
    }
}

struct ContentBlockerListView: View {
    @StateObject private var adBlockManager = AdBlockManager.shared

    var body: some View {
        List {
            Section(header: Text("Active Filters")) {
                ForEach(adBlockManager.activeFilterLists, id: \.self) { filter in
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text(filter)
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Info")) {
                HStack {
                    Text("Total Rules")
                    Spacer()
                    Text("\(adBlockManager.totalRuleCount)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(adBlockManager.lastUpdateString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Content Blockers")
    }
}
