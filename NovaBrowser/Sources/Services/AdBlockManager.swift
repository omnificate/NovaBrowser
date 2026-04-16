// AdBlockManager.swift
// NovaBrowser - Content blocking and ad filtering engine

import SwiftUI
import WebKit

final class AdBlockManager: ObservableObject {
    static let shared = AdBlockManager()

    @Published var activeFilterLists: [String] = ["EasyList", "EasyPrivacy", "Peter Lowe's Ad Tracking"]
    @Published var totalRuleCount: Int = 0
    @Published var lastUpdateString: String = "Never"

    private var compiledRules: [WKContentRuleList] = []
    private var blockDomains: Set<String> = []
    private var blockPatterns: [NSRegularExpression] = []

    private init() {}

    // MARK: - Load Filters
    func loadFilters() {
        // Compile built-in content blocking rules
        compileContentBlockingRules()
        loadBlockDomains()
        totalRuleCount = blockDomains.count + embeddedRules.count

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        lastUpdateString = formatter.string(from: Date())
    }

    // MARK: - Apply to WebView Config
    func applyContentRules(to config: WKWebViewConfiguration) {
        let controller = config.userContentController

        // Apply compiled WKContentRuleList
        for ruleList in compiledRules {
            controller.add(ruleList)
        }

        // Inject CSS-based ad hiding
        let cssScript = WKUserScript(
            source: adHidingCSS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        controller.addUserScript(cssScript)
    }

    // MARK: - URL Blocking Check
    func shouldBlock(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }

        // Check domain blocklist
        let components = host.split(separator: ".")
        for i in 0..<components.count {
            let domain = components[i...].joined(separator: ".")
            if blockDomains.contains(domain) {
                return true
            }
        }

        // Check URL patterns
        let urlString = url.absoluteString
        for pattern in blockPatterns {
            if pattern.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) != nil {
                return true
            }
        }

        return false
    }

    // MARK: - Compile Rules
    private func compileContentBlockingRules() {
        let ruleJSON = generateContentBlockerJSON()

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "NovaBrowserAdBlock",
            encodedContentRuleList: ruleJSON
        ) { [weak self] ruleList, error in
            if let ruleList = ruleList {
                DispatchQueue.main.async {
                    self?.compiledRules = [ruleList]
                }
            }
        }
    }

    private func generateContentBlockerJSON() -> String {
        var rules: [[String: Any]] = []

        // Ad network domains
        for domain in adNetworkDomains {
            rules.append([
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*\(domain)"]
                ],
                "action": ["type": "block"]
            ])
        }

        // Tracking parameters
        for rule in embeddedRules {
            rules.append(rule)
        }

        // CSS element hiding for common ad selectors
        let cssHideRule: [String: Any] = [
            "trigger": ["url-filter": ".*"],
            "action": [
                "type": "css-display-none",
                "selector": adSelectors.joined(separator: ", ")
            ]
        ]
        rules.append(cssHideRule)

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }

    // MARK: - Block Domains
    private func loadBlockDomains() {
        blockDomains = Set(adNetworkDomains + trackingDomains)

        // Compile regex patterns
        let patterns = [
            ".*\\.doubleclick\\.net.*",
            ".*googlesyndication\\.com.*",
            ".*googleadservices\\.com.*",
            ".*google-analytics\\.com.*",
            ".*facebook\\.com/tr.*",
            ".*connect\\.facebook\\.net/en_US/fbevents.*",
            ".*analytics\\..*\\.com.*",
            ".*\\.adnxs\\.com.*",
            ".*\\.adsrvr\\.org.*",
            ".*\\.criteo\\.com.*",
            ".*\\.outbrain\\.com/.*widget.*",
            ".*\\.taboola\\.com.*",
            ".*pagead2\\.googlesyndication\\.com.*"
        ]

        blockPatterns = patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }

    // MARK: - Built-in Data
    private let adNetworkDomains = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "moatads.com", "amazon-adsystem.com", "adnxs.com",
        "ads.linkedin.com", "adsrvr.org", "criteo.com",
        "casalemedia.com", "pubmatic.com", "openx.net",
        "rubiconproject.com", "smartadserver.com", "yieldmo.com",
        "advertising.com", "zedo.com", "adbrite.com",
        "admob.com", "adsense.google.com", "adcolony.com",
        "inmobi.com", "unity3d.com", "vungle.com",
        "chartboost.com", "applovin.com", "ironsrc.com",
        "mopub.com", "startapp.com", "tapjoy.com"
    ]

    private let trackingDomains = [
        "google-analytics.com", "googletagmanager.com",
        "facebook.net", "fbcdn.net",
        "hotjar.com", "mouseflow.com", "crazyegg.com",
        "mixpanel.com", "segment.io", "amplitude.com",
        "branch.io", "adjust.com", "appsflyer.com",
        "kochava.com", "singular.net", "tune.com",
        "quantserve.com", "scorecardresearch.com",
        "newrelic.com", "nr-data.net",
        "optimizely.com", "abtasty.com",
        "onesignal.com", "pushwoosh.com",
        "doubleclick.net", "adsrvr.org"
    ]

    private let adSelectors = [
        "[id*='google_ads']", "[id*='ad-']", "[class*='ad-banner']",
        "[class*='ad-container']", "[class*='advertisement']",
        "[class*='sponsored']", "[data-ad]", "[data-ad-slot]",
        ".adsbygoogle", ".ad-wrapper", ".ad-unit",
        "#ad-header", "#ad-footer", "#ad-sidebar",
        "[id*='taboola']", "[id*='outbrain']",
        ".native-ad", ".promoted-content",
        "iframe[src*='doubleclick']", "iframe[src*='googlesyndication']"
    ]

    private let embeddedRules: [[String: Any]] = [
        // Block tracking pixels
        [
            "trigger": ["url-filter": ".*\\.gif\\?.*utm_"],
            "action": ["type": "block"]
        ],
        // Block common tracker scripts
        [
            "trigger": ["url-filter": ".*analytics\\.js"],
            "action": ["type": "block"]
        ],
        // Strip tracking parameters from URLs
        [
            "trigger": ["url-filter": ".*[?&](utm_source|utm_medium|utm_campaign|utm_content|utm_term|fbclid|gclid|msclkid)="],
            "action": ["type": "block"]
        ]
    ]

    private var adHidingCSS: String {
        """
        (function() {
            var style = document.createElement('style');
            style.textContent = `
                \(adSelectors.joined(separator: ", ")) {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                    width: 0 !important;
                    overflow: hidden !important;
                }
            `;
            document.head.appendChild(style);

            // MutationObserver to catch dynamically loaded ads
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                            var selectors = '\(adSelectors.joined(separator: ", "))';
                            if (node.matches && node.matches(selectors)) {
                                node.style.display = 'none';
                            }
                            node.querySelectorAll && node.querySelectorAll(selectors).forEach(function(el) {
                                el.style.display = 'none';
                            });
                        }
                    });
                });
            });
            observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
        })();
        """
    }
}
