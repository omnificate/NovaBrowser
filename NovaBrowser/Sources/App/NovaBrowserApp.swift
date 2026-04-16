// NovaBrowserApp.swift
// NovaBrowser - The Ultimate iOS Browser
// Supports iOS 14.0+ with graceful degradation
// CyberKit-enhanced WebKit engine for jailbroken/TrollStore devices

import SwiftUI

@main
struct NovaBrowserApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) var scenePhase

    init() {
        // Initialize core services
        StorageManager.shared.initialize()
        AdBlockManager.shared.loadFilters()
        DownloadManager.shared.resumePendingDownloads()

        // Configure appearance
        configureGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainBrowserView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onOpenURL { url in
                    appState.openURL(url)
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }

    private func configureGlobalAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Save state
            appState.saveState()
            StorageManager.shared.persistAll()
        case .active:
            // Resume
            appState.resumeFromBackground()
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
