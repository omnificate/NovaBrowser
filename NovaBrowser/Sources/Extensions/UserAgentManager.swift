// UserAgentManager.swift
// NovaBrowser - User agent string management

import UIKit
import WebKit

enum UserAgentManager {
    private static var cachedUserAgent: String?

    /// Default mobile user agent
    static var defaultUserAgent: String {
        if let cached = cachedUserAgent {
            return cached
        }

        let webView = WKWebView()
        webView.evaluateJavaScript("navigator.userAgent") { result, _ in
            if let ua = result as? String {
                cachedUserAgent = ua.replacingOccurrences(of: "Mobile/", with: "Mobile/NovaBrowser/1.0 ")
            }
        }

        // Fallback
        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let model = UIDevice.current.model
        return "Mozilla/5.0 (\(model); CPU \(model) OS \(systemVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 NovaBrowser/1.0"
    }

    /// Desktop user agent for requesting desktop sites
    static var desktopUserAgent: String {
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
    }

    /// Chrome-like user agent
    static var chromeUserAgent: String {
        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion) like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
    }

    /// Firefox-like user agent
    static var firefoxUserAgent: String {
        let systemVersion = UIDevice.current.systemVersion
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/120.0 Mobile/15E148 Safari/605.1.15"
    }
}
