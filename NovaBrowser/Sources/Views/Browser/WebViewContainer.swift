// WebViewContainer.swift
// NovaBrowser - WKWebView wrapper with full delegate handling

import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var tab: BrowserTab

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = tab.getOrCreateWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator

        // Long press gesture for link preview
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        webView.addGestureRecognizer(longPress)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Updates handled via observations in BrowserTab
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
        let tab: BrowserTab
        private var lastScrollOffset: CGFloat = 0

        init(tab: BrowserTab) {
            self.tab = tab
            super.init()
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""

            // Handle special schemes
            switch scheme {
            case "tel", "mailto", "sms", "facetime":
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            case "itms-appss", "itms-apps", "itms":
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            case "blob", "data":
                decisionHandler(.allow)
                return
            default:
                break
            }

            // Block trackers and ads
            if SettingsManager.shared.adBlockingEnabled {
                if AdBlockManager.shared.shouldBlock(url: url) {
                    decisionHandler(.cancel)
                    return
                }
            }

            // Handle target="_blank" links
            if navigationAction.targetFrame == nil {
                // Open in new tab
                DispatchQueue.main.async {
                    AppState.shared.createNewTab(url: url)
                }
                decisionHandler(.cancel)
                return
            }

            // Download detection
            if let mimeType = navigationAction.request.value(forHTTPHeaderField: "Content-Type"),
               DownloadManager.shared.shouldDownload(mimeType: mimeType) {
                DownloadManager.shared.startDownload(url: url, suggestedFilename: url.lastPathComponent)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            guard let response = navigationResponse.response as? HTTPURLResponse else {
                decisionHandler(.allow)
                return
            }

            let mimeType = response.mimeType ?? ""

            // Check if this should be a download
            if !navigationResponse.canShowMIMEType || DownloadManager.shared.shouldDownload(mimeType: mimeType) {
                if let url = response.url {
                    let filename = response.suggestedFilename ?? url.lastPathComponent
                    DownloadManager.shared.startDownload(url: url, suggestedFilename: filename)
                }
                decisionHandler(.cancel)
                return
            }

            // Record in history
            if let url = response.url, !tab.isPrivate {
                let title = webView.title ?? url.host ?? "Untitled"
                HistoryManager.shared.addToHistory(title: title, url: url.absoluteString)
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.tab.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Extract favicon
            extractFavicon(from: webView)

            // Capture screenshot for tab switcher
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tab.captureScreenshot { _ in }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleNavigationError(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleNavigationError(error)
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Handle SSL/TLS challenges
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
                        challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest {
                // Show auth dialog
                DispatchQueue.main.async {
                    self.showAuthenticationDialog(challenge: challenge, completionHandler: completionHandler)
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Open links targeting new windows in a new tab
            if let url = navigationAction.request.url {
                DispatchQueue.main.async {
                    AppState.shared.createNewTab(url: url)
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let host = frame.request.url?.host ?? "This page"
            let alert = UIAlertController(title: host, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })

            topViewController()?.present(alert, animated: true) {
                // If dismissed without action
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let host = frame.request.url?.host ?? "This page"
            let alert = UIAlertController(title: host, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            topViewController()?.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let host = frame.request.url?.host ?? "This page"
            let alert = UIAlertController(title: host, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            topViewController()?.present(alert, animated: true)
        }

        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            let alert = UIAlertController(
                title: "Permission Request",
                message: "\(origin.host) wants to access your \(type == .camera ? "camera" : type == .microphone ? "microphone" : "camera and microphone")",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Deny", style: .cancel) { _ in decisionHandler(.deny) })
            alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in decisionHandler(.grant) })
            topViewController()?.present(alert, animated: true)
        }

        // MARK: - Context Menu (iOS 13+)
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
            guard let url = elementInfo.linkURL else {
                completionHandler(nil)
                return
            }

            let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                var actions: [UIAction] = []

                actions.append(UIAction(title: "Open in New Tab", image: UIImage(systemName: "plus.square")) { _ in
                    AppState.shared.createNewTab(url: url)
                })

                actions.append(UIAction(title: "Open in Background", image: UIImage(systemName: "square.stack")) { _ in
                    AppState.shared.createNewTab(url: url, switchTo: false)
                })

                actions.append(UIAction(title: "Copy Link", image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = url.absoluteString
                })

                actions.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                    let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    self.topViewController()?.present(ac, animated: true)
                })

                actions.append(UIAction(title: "Download Link", image: UIImage(systemName: "arrow.down.circle")) { _ in
                    DownloadManager.shared.startDownload(url: url, suggestedFilename: url.lastPathComponent)
                })

                actions.append(UIAction(title: "Add to Bookmarks", image: UIImage(systemName: "bookmark")) { _ in
                    BookmarkManager.shared.addBookmark(
                        title: url.host ?? "Link",
                        url: url.absoluteString
                    )
                })

                return UIMenu(title: url.absoluteString, children: actions)
            }

            completionHandler(config)
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.y
            let diff = offset - lastScrollOffset

            if diff > 10 && offset > 50 {
                // Scrolling down - hide bars
                withAnimation(.easeOut(duration: 0.2)) {
                    AppState.shared.isFullScreen = true
                }
            } else if diff < -10 {
                // Scrolling up - show bars
                withAnimation(.easeOut(duration: 0.2)) {
                    AppState.shared.isFullScreen = false
                }
            }

            lastScrollOffset = offset
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView.contentOffset.y <= 0 {
                withAnimation(.easeOut(duration: 0.2)) {
                    AppState.shared.isFullScreen = false
                }
            }
        }

        // MARK: - Helpers

        private func handleNavigationError(_ error: Error) {
            let nsError = error as NSError

            // Ignore cancelled requests
            if nsError.code == NSURLErrorCancelled { return }

            // Ignore frame load interrupted (usually from new navigations)
            if nsError.code == 102 { return }

            DispatchQueue.main.async {
                self.tab.errorMessage = self.userFriendlyError(nsError)
            }
        }

        private func userFriendlyError(_ error: NSError) -> String {
            switch error.code {
            case NSURLErrorNotConnectedToInternet:
                return "No Internet Connection\nPlease check your network settings and try again."
            case NSURLErrorTimedOut:
                return "Request Timed Out\nThe server took too long to respond."
            case NSURLErrorCannotFindHost:
                return "Server Not Found\nThe website couldn't be reached."
            case NSURLErrorSecureConnectionFailed:
                return "Connection Not Secure\nThere was a problem with the security certificate."
            case NSURLErrorNetworkConnectionLost:
                return "Connection Lost\nThe network connection was lost. Please try again."
            default:
                return "Failed to Load Page\n\(error.localizedDescription)"
            }
        }

        private func extractFavicon(from webView: WKWebView) {
            let js = """
            (function() {
                var links = document.querySelectorAll('link[rel*="icon"]');
                if (links.length > 0) {
                    var best = links[links.length - 1];
                    for (var i = 0; i < links.length; i++) {
                        var sizes = links[i].getAttribute('sizes');
                        if (sizes && parseInt(sizes) >= 32) {
                            best = links[i];
                            break;
                        }
                    }
                    return best.href;
                }
                return window.location.origin + '/favicon.ico';
            })();
            """

            webView.evaluateJavaScript(js) { [weak self] result, _ in
                if let urlString = result as? String, let url = URL(string: urlString) {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.tab.favicon = image
                            }
                        }
                    }.resume()
                }
            }
        }

        private func showAuthenticationDialog(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let alert = UIAlertController(
                title: "Authentication Required",
                message: "Sign in to \(challenge.protectionSpace.host)",
                preferredStyle: .alert
            )
            alert.addTextField { $0.placeholder = "Username" }
            alert.addTextField { $0.placeholder = "Password"; $0.isSecureTextEntry = true }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(.cancelAuthenticationChallenge, nil)
            })
            alert.addAction(UIAlertAction(title: "Sign In", style: .default) { _ in
                let credential = URLCredential(
                    user: alert.textFields?[0].text ?? "",
                    password: alert.textFields?[1].text ?? "",
                    persistence: .forSession
                )
                completionHandler(.useCredential, credential)
            })
            topViewController()?.present(alert, animated: true)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // Handled by context menu on iOS 13+
        }

        private func topViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return nil }
            var top = window.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
    }
}
