// MainBrowserView.swift
// NovaBrowser - Main browser interface

import SwiftUI

struct MainBrowserView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var addressBarVM = AddressBarViewModel()
    @State private var showMenu = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top safe area color match
                if !appState.isFullScreen {
                    statusBarBackground
                }

                // Web content
                webContentArea

                // Bottom toolbar
                if !appState.isFullScreen {
                    bottomBar
                }
            }

            // Overlays
            overlays
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $appState.isShowingSettings) {
            SettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $appState.isShowingBookmarks) {
            BookmarksView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isShowingHistory) {
            HistoryView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isShowingDownloads) {
            DownloadsView()
        }
        .sheet(isPresented: $appState.isShowingShareSheet) {
            if let url = appState.activeTab?.currentURL {
                ShareSheet(items: [url])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    // MARK: - Status Bar Background
    private var statusBarBackground: some View {
        Rectangle()
            .fill(appState.isPrivateBrowsing ?
                  Color.purple.opacity(0.15) :
                    themeManager.toolbarColor)
            .frame(height: 0)
    }

    // MARK: - Web Content Area
    private var webContentArea: some View {
        ZStack {
            if let tab = appState.activeTab {
                WebViewContainer(tab: tab)
                    .id(tab.id)

                // Progress bar
                if tab.isLoading {
                    VStack {
                        ProgressBar(value: tab.estimatedProgress)
                        Spacer()
                    }
                }

                // Error overlay
                if let error = tab.errorMessage {
                    ErrorOverlayView(message: error) {
                        tab.reload()
                    }
                }
            } else {
                NewTabPageView()
                    .environmentObject(appState)
            }

            // Find in page bar
            if appState.isShowingFindInPage {
                VStack {
                    FindInPageBar(tab: appState.activeTab)
                    Spacer()
                }
                .transition(.move(edge: .top))
            }
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            // Address bar
            AddressBar(viewModel: addressBarVM)
                .environmentObject(appState)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            // Toolbar
            HStack(spacing: 0) {
                toolbarButton(icon: "chevron.left", enabled: appState.activeTab?.canGoBack ?? false) {
                    appState.activeTab?.goBack()
                }

                toolbarButton(icon: "chevron.right", enabled: appState.activeTab?.canGoForward ?? false) {
                    appState.activeTab?.goForward()
                }

                toolbarButton(icon: "square.and.arrow.up") {
                    appState.isShowingShareSheet = true
                }

                toolbarButton(icon: "book") {
                    appState.isShowingBookmarks = true
                }

                // Tab counter button
                Button(action: { withAnimation(.spring(response: 0.3)) { appState.isShowingTabs = true } }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(themeManager.accentColor, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        Text("\(appState.tabs.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)

                toolbarButton(icon: "ellipsis") {
                    showMenu = true
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            .background(
                themeManager.toolbarColor
                    .shadow(color: .black.opacity(0.1), radius: 2, y: -1)
            )
        }
        .background(themeManager.toolbarColor)
        .actionSheet(isPresented: $showMenu) {
            menuActionSheet
        }
    }

    private func toolbarButton(icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(enabled ? themeManager.accentColor : .gray)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .disabled(!enabled)
    }

    // MARK: - Overlays
    private var overlays: some View {
        Group {
            // Tab switcher
            if appState.isShowingTabs {
                TabSwitcherView()
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }

            // Suggestions overlay
            if addressBarVM.showSuggestions && !addressBarVM.suggestions.isEmpty {
                VStack {
                    Spacer()
                    SuggestionsOverlay(
                        suggestions: addressBarVM.suggestions,
                        onSelect: { suggestion in
                            addressBarVM.selectSuggestion(suggestion)
                            appState.navigateToAddressBarInput(suggestion)
                        }
                    )
                    .padding(.bottom, 120 + keyboardHeight)
                }
                .transition(.opacity)
                .zIndex(50)
            }
        }
    }

    // MARK: - Menu
    private var menuActionSheet: ActionSheet {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("New Tab")) {
            appState.createNewTab()
        })

        buttons.append(.default(Text(appState.isPrivateBrowsing ? "Exit Private Browsing" : "Private Browsing")) {
            appState.togglePrivateBrowsing()
        })

        buttons.append(.default(Text("Find in Page")) {
            withAnimation { appState.isShowingFindInPage.toggle() }
        })

        buttons.append(.default(Text("History")) {
            appState.isShowingHistory = true
        })

        buttons.append(.default(Text("Downloads")) {
            appState.isShowingDownloads = true
        })

        if let tab = appState.activeTab {
            buttons.append(.default(Text("Add Bookmark")) {
                if let url = tab.currentURL {
                    BookmarkManager.shared.addBookmark(
                        title: tab.title,
                        url: url.absoluteString
                    )
                }
            })

            buttons.append(.default(Text("Reader Mode")) {
                ReaderModeManager.shared.toggleReaderMode(for: tab)
            })

            buttons.append(.default(Text("Request Desktop Site")) {
                tab.webView?.customUserAgent = UserAgentManager.desktopUserAgent
                tab.reload()
            })

            if tab.isLoading {
                buttons.append(.default(Text("Stop Loading")) {
                    tab.stopLoading()
                })
            } else {
                buttons.append(.default(Text("Reload")) {
                    tab.reloadFromOrigin()
                })
            }
        }

        buttons.append(.default(Text("Settings")) {
            appState.isShowingSettings = true
        })

        buttons.append(.cancel())

        return ActionSheet(title: Text("Menu"), buttons: buttons)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 2.5)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(value), height: 2.5)
                    .animation(.linear(duration: 0.2), value: value)
            }
        }
        .frame(height: 2.5)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
