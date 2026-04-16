// TabSwitcherView.swift
// NovaBrowser - Card-based tab switcher inspired by Safari

import SwiftUI

struct TabSwitcherView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dragOffset: CGFloat = 0
    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Tab grid
                tabGrid

                // Bottom toolbar
                bottomToolbar
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button("Done") {
                withAnimation(.spring(response: 0.3)) {
                    appState.isShowingTabs = false
                }
            }
            .font(.system(size: 17, weight: .semibold))

            Spacer()

            Text(appState.isPrivateBrowsing ? "Private Tabs" : "\(appState.tabs.count) Tabs")
                .font(.headline)

            Spacer()

            Button(action: { appState.createNewTab() }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Tab Grid
    private var tabGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                    TabCard(
                        tab: tab,
                        isActive: index == appState.activeTabIndex,
                        onSelect: {
                            appState.switchToTab(at: index)
                        },
                        onClose: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                appState.closeTab(at: index)
                            }
                        }
                    )
                }
            }
            .padding(12)
        }
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack {
            // Private browsing toggle
            Button(action: { appState.togglePrivateBrowsing() }) {
                HStack(spacing: 6) {
                    Image(systemName: appState.isPrivateBrowsing ? "eye.slash.fill" : "eye.slash")
                        .font(.system(size: 14))
                    Text("Private")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(appState.isPrivateBrowsing ? .purple : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    appState.isPrivateBrowsing ?
                    Color.purple.opacity(0.15) : Color(.systemGray5)
                )
                .cornerRadius(20)
            }

            Spacer()

            // Close all tabs
            if appState.tabs.count > 1 {
                Button("Close All") {
                    appState.closeAllTabs()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            }

            Spacer()

            // New tab
            Button(action: {
                appState.createNewTab()
                withAnimation(.spring(response: 0.3)) {
                    appState.isShowingTabs = false
                }
            }) {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Tab Card
struct TabCard: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 6) {
                    if let favicon = tab.favicon {
                        Image(uiImage: favicon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

                // Screenshot
                ZStack {
                    if let screenshot = tab.screenshot {
                        Image(uiImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    if let host = tab.currentURL?.host {
                                        Text(host)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                    }

                    // Loading overlay
                    if tab.isLoading {
                        Color.black.opacity(0.1)
                        ProgressView()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
