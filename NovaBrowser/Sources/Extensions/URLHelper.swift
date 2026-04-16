// URLHelper.swift
// NovaBrowser - URL parsing, resolution, and display utilities

import Foundation

enum URLHelper {
    /// Resolves user input to a URL - either a search query or direct URL
    static func resolveInput(_ input: String) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Already a valid URL with scheme
        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            return url
        }

        // Looks like a URL (contains dot, no spaces)
        if trimmed.contains(".") && !trimmed.contains(" ") {
            // Try with https
            if let url = URL(string: "https://\(trimmed)") {
                return url
            }
        }

        // IP address
        if isIPAddress(trimmed) {
            if let url = URL(string: "http://\(trimmed)") {
                return url
            }
        }

        // localhost
        if trimmed.hasPrefix("localhost") {
            if let url = URL(string: "http://\(trimmed)") {
                return url
            }
        }

        // Treat as search query
        return searchURL(for: trimmed)
    }

    /// Creates a search URL for the given query
    static func searchURL(for query: String) -> URL {
        let engine = SettingsManager.shared.searchEngine
        return engine.searchURL(for: query) ?? URL(string: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)")!
    }

    /// Returns a clean display string for a URL
    static func displayString(for url: URL) -> String {
        var display = url.absoluteString

        // Remove scheme for cleaner display
        if display.hasPrefix("https://") {
            display = String(display.dropFirst(8))
        } else if display.hasPrefix("http://") {
            display = String(display.dropFirst(7))
        }

        // Remove trailing slash
        if display.hasSuffix("/") {
            display = String(display.dropLast())
        }

        // Remove www.
        if display.hasPrefix("www.") {
            display = String(display.dropFirst(4))
        }

        return display
    }

    /// Returns just the host portion for display
    static func displayHost(for urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else {
            return urlString
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Checks if a string is an IP address
    static func isIPAddress(_ string: String) -> Bool {
        let parts = string.split(separator: ":")
        let address = String(parts.first ?? Substring(string))

        let ipv4Pattern = "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"
        if address.range(of: ipv4Pattern, options: .regularExpression) != nil {
            return true
        }

        // Simple IPv6 check
        if address.contains(":") && address.range(of: "[0-9a-fA-F:]+", options: .regularExpression) != nil {
            return true
        }

        return false
    }

    /// Upgrades HTTP to HTTPS if setting enabled
    static func upgradeToHTTPS(_ url: URL) -> URL {
        guard SettingsManager.shared.httpsUpgrade,
              url.scheme == "http",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.scheme = "https"
        return components.url ?? url
    }
}
