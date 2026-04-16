// BrowserTab.swift
// NovaBrowser - Tab model with full WebView lifecycle management

import SwiftUI
import WebKit
import Combine

final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()

    // MARK: - Published
    @Published var title: String = "New Tab"
    @Published var currentURL: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0
    @Published var favicon: UIImage?
    @Published var screenshot: UIImage?
    @Published var isSecure: Bool = false
    @Published var hasOnlySecureContent: Bool = false
    @Published var errorMessage: String?

    // MARK: - Properties
    let isPrivate: Bool
    var lastAccessTime: Date = Date()
    var webView: WKWebView?
    private var observations = Set<NSKeyValueObservation>()
    private var cancellables = Set<AnyCancellable>()

    // History within this tab
    var backForwardList: WKBackForwardList? {
        webView?.backForwardList
    }

    init(url: URL? = nil, isPrivate: Bool = false) {
        self.isPrivate = isPrivate
        self.currentURL = url
    }

    // MARK: - WebView Configuration
    func getOrCreateWebView() -> WKWebView {
        if let existing = webView { return existing }

        let config = createWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.allowsLinkPreview = true

        if #available(iOS 16.4, *) {
            wv.isInspectable = true
        }

        // Performance optimizations
        wv.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        setupObservations(for: wv)
        self.webView = wv

        if let url = currentURL {
            wv.load(URLRequest(url: url))
        }

        return wv
    }

    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        // Data store - private or persistent
        if isPrivate {
            config.websiteDataStore = .nonPersistent()
        } else {
            config.websiteDataStore = .default()
        }

        // Process pool for isolation
        config.processPool = ProcessPoolManager.shared.getPool(isPrivate: isPrivate)

        // Preferences
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = false
        if #available(iOS 15.4, *) {
            // Enable modern features
        }
        config.preferences = prefs

        // Web page preferences
        let webPrefs = WKWebpagePreferences()
        webPrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = webPrefs

        // Media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = [.all]

        // Content rules (ad blocking)
        if SettingsManager.shared.adBlockingEnabled {
            AdBlockManager.shared.applyContentRules(to: config)
        }

        // User scripts
        injectUserScripts(into: config)

        return config
    }

    private func injectUserScripts(into config: WKWebViewConfiguration) {
        let controller = config.userContentController

        // Reader mode detection script
        let readerScript = WKUserScript(
            source: ReaderModeScripts.detectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        controller.addUserScript(readerScript)

        // Viewport meta tag fixer for old sites
        let viewportScript = WKUserScript(
            source: """
            (function() {
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0';
                    document.head.appendChild(meta);
                }
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        controller.addUserScript(viewportScript)

        // Dark mode CSS injection
        if ThemeManager.shared.forceDarkMode {
            let darkScript = WKUserScript(
                source: DarkModeScripts.injectionScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            controller.addUserScript(darkScript)
        }
    }

    // MARK: - Observations
    private func setupObservations(for wv: WKWebView) {
        observations.insert(
            wv.observe(\.title) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.title = wv.title ?? "Untitled"
                }
            }
        )

        observations.insert(
            wv.observe(\.url) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.currentURL = wv.url
                    self?.isSecure = wv.url?.scheme == "https"
                    self?.lastAccessTime = Date()
                }
            }
        )

        observations.insert(
            wv.observe(\.canGoBack) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.canGoBack = wv.canGoBack
                }
            }
        )

        observations.insert(
            wv.observe(\.canGoForward) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.canGoForward = wv.canGoForward
                }
            }
        )

        observations.insert(
            wv.observe(\.isLoading) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.isLoading = wv.isLoading
                }
            }
        )

        observations.insert(
            wv.observe(\.estimatedProgress) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.estimatedProgress = wv.estimatedProgress
                }
            }
        )

        observations.insert(
            wv.observe(\.hasOnlySecureContent) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.hasOnlySecureContent = wv.hasOnlySecureContent
                }
            }
        )
    }

    // MARK: - Navigation
    func loadURL(_ url: URL) {
        currentURL = url
        errorMessage = nil
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView?.load(request)
    }

    func loadHTMLString(_ html: String, baseURL: URL? = nil) {
        webView?.loadHTMLString(html, baseURL: baseURL)
    }

    func reload() {
        webView?.reload()
    }

    func reloadFromOrigin() {
        webView?.reloadFromOrigin()
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func stopLoading() {
        webView?.stopLoading()
    }

    // MARK: - Find in Page
    func findInPage(_ query: String) {
        guard !query.isEmpty else {
            clearFindInPage()
            return
        }
        if #available(iOS 16.0, *) {
            webView?.find(query, configuration: .init()) { _ in }
        } else {
            let js = "window.find('\(query.replacingOccurrences(of: "'", with: "\\'"))', false, false, true)"
            webView?.evaluateJavaScript(js)
        }
    }

    func clearFindInPage() {
        if #available(iOS 16.0, *) {
            // Dismiss find interaction
        }
        webView?.evaluateJavaScript("window.getSelection().removeAllRanges()")
    }

    // MARK: - Screenshot
    func captureScreenshot(completion: @escaping (UIImage?) -> Void) {
        guard let wv = webView else {
            completion(nil)
            return
        }

        let config = WKSnapshotConfiguration()
        config.snapshotWidth = 200

        wv.takeSnapshot(with: config) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.screenshot = image
                completion(image)
            }
        }
    }

    // MARK: - Cleanup
    func cleanup() {
        webView?.stopLoading()
        webView?.configuration.userContentController.removeAllUserScripts()
        observations.removeAll()
        cancellables.removeAll()
        webView = nil

        if isPrivate {
            // Clear private data
        }
    }

    deinit {
        cleanup()
    }
}

// MARK: - Hashable
extension BrowserTab: Hashable {
    static func == (lhs: BrowserTab, rhs: BrowserTab) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Process Pool Manager
final class ProcessPoolManager {
    static let shared = ProcessPoolManager()
    private var normalPool = WKProcessPool()
    private var privatePool = WKProcessPool()

    func getPool(isPrivate: Bool) -> WKProcessPool {
        isPrivate ? privatePool : normalPool
    }

    func resetPrivatePool() {
        privatePool = WKProcessPool()
    }
}
