// SettingsManager.swift
// NovaBrowser - Centralized settings with UserDefaults persistence

import SwiftUI
import Combine
import WebKit

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - General
    @AppStorage("searchEngine") var searchEngine: SearchEngine = .google
    @AppStorage("homePageURL") var homePageURL: String = ""
    @AppStorage("openLinksInNewTab") var openLinksInNewTab: Bool = false
    @AppStorage("showSearchSuggestions") var showSearchSuggestions: Bool = true
    @AppStorage("quickWebsiteSearch") var quickWebsiteSearch: Bool = true
    @AppStorage("preloadTopHit") var preloadTopHit: Bool = false

    // MARK: - Privacy
    @AppStorage("adBlockingEnabled") var adBlockingEnabled: Bool = true
    @AppStorage("blockPopups") var blockPopups: Bool = true
    @AppStorage("doNotTrack") var doNotTrack: Bool = true
    @AppStorage("blockCookies") var blockCookies: Bool = false
    @AppStorage("httpsUpgrade") var httpsUpgrade: Bool = true
    @AppStorage("fraudulentWebsiteWarning") var fraudulentWebsiteWarning: Bool = true

    // MARK: - Content
    @AppStorage("enableJavaScript") var enableJavaScript: Bool = true
    @AppStorage("enableImages") var enableImages: Bool = true
    @AppStorage("autoplayVideos") var autoplayVideos: Bool = false
    @AppStorage("pageFontSize") var pageFontSize: Double = 100

    // MARK: - Performance
    @AppStorage("enablePrefetch") var enablePrefetch: Bool = true
    @AppStorage("hardwareAcceleration") var hardwareAcceleration: Bool = true
    @AppStorage("compressData") var compressData: Bool = false
    @AppStorage("cacheSizeLimit") var cacheSizeLimit: Int = 200

    // MARK: - User Agent
    @AppStorage("customUserAgent") var customUserAgent: String = ""
    @AppStorage("useDesktopMode") var useDesktopMode: Bool = false

    private init() {}

    func resetAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
