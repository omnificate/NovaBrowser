// ReaderModeScripts.swift
// NovaBrowser - Reader mode detection and content extraction

import Foundation

enum ReaderModeScripts {
    /// Script to detect if a page is suitable for reader mode
    static let detectionScript = """
    (function() {
        function isReaderable() {
            var start = Date.now();
            var bodyText = document.body ? document.body.innerText : '';
            if (bodyText.length < 500) return false;

            var paragraphs = document.querySelectorAll('p');
            var totalLength = 0;
            var validParagraphs = 0;

            for (var i = 0; i < paragraphs.length; i++) {
                var text = paragraphs[i].innerText.trim();
                if (text.length > 50) {
                    totalLength += text.length;
                    validParagraphs++;
                }
            }

            return validParagraphs >= 3 && totalLength > 500;
        }

        window.__novaReaderAvailable = isReaderable();
    })();
    """

    /// Script to extract article content for reader mode
    static let extractionScript = """
    (function() {
        function extractArticle() {
            // Try to find the main article content
            var article = null;
            var selectors = [
                'article',
                '[role="main"]',
                'main',
                '.post-content',
                '.article-content',
                '.entry-content',
                '.content-body',
                '#article-body',
                '.story-body'
            ];

            for (var i = 0; i < selectors.length; i++) {
                article = document.querySelector(selectors[i]);
                if (article && article.innerText.length > 200) break;
                article = null;
            }

            if (!article) {
                // Fallback: find the largest text block
                var blocks = document.querySelectorAll('div, section');
                var maxLength = 0;

                for (var j = 0; j < blocks.length; j++) {
                    var text = blocks[j].innerText;
                    if (text.length > maxLength) {
                        maxLength = text.length;
                        article = blocks[j];
                    }
                }
            }

            if (!article) return null;

            // Extract metadata
            var title = '';
            var h1 = document.querySelector('h1');
            if (h1) title = h1.innerText;
            else title = document.title;

            var author = '';
            var authorMeta = document.querySelector('meta[name="author"]') ||
                            document.querySelector('[rel="author"]') ||
                            document.querySelector('.author');
            if (authorMeta) author = authorMeta.content || authorMeta.innerText || '';

            var date = '';
            var dateMeta = document.querySelector('time') ||
                          document.querySelector('meta[property="article:published_time"]') ||
                          document.querySelector('.date, .published');
            if (dateMeta) date = dateMeta.getAttribute('datetime') || dateMeta.content || dateMeta.innerText || '';

            var siteName = '';
            var siteNameMeta = document.querySelector('meta[property="og:site_name"]');
            if (siteNameMeta) siteName = siteNameMeta.content || '';

            // Get hero image
            var heroImage = '';
            var ogImage = document.querySelector('meta[property="og:image"]');
            if (ogImage) heroImage = ogImage.content;
            else {
                var firstImg = article.querySelector('img[src]');
                if (firstImg) heroImage = firstImg.src;
            }

            // Clean the HTML content
            var clone = article.cloneNode(true);

            // Remove unwanted elements
            var removeSelectors = [
                'script', 'style', 'iframe', 'nav', 'aside', 'footer',
                '.ad', '.advertisement', '.social-share', '.comments',
                '.related-articles', '[role="complementary"]',
                '.sidebar', '.popup', '.modal', '.newsletter-signup'
            ];
            removeSelectors.forEach(function(sel) {
                clone.querySelectorAll(sel).forEach(function(el) { el.remove(); });
            });

            return {
                title: title,
                author: author,
                date: date,
                siteName: siteName,
                heroImage: heroImage,
                content: clone.innerHTML,
                textContent: clone.innerText,
                wordCount: clone.innerText.split(/\\s+/).length,
                url: window.location.href
            };
        }

        return JSON.stringify(extractArticle());
    })();
    """
}

// MARK: - Reader Mode Manager
final class ReaderModeManager {
    static let shared = ReaderModeManager()

    func toggleReaderMode(for tab: BrowserTab) {
        guard let webView = tab.webView else { return }

        webView.evaluateJavaScript(ReaderModeScripts.extractionScript) { [weak self] result, error in
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let article = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }

            let html = self?.generateReaderHTML(from: article) ?? ""
            tab.loadHTMLString(html, baseURL: tab.currentURL)
        }
    }

    private func generateReaderHTML(from article: [String: Any]) -> String {
        let title = article["title"] as? String ?? ""
        let author = article["author"] as? String ?? ""
        let date = article["date"] as? String ?? ""
        let siteName = article["siteName"] as? String ?? ""
        let content = article["content"] as? String ?? ""
        let wordCount = article["wordCount"] as? Int ?? 0
        let readTime = max(1, wordCount / 200)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, Georgia, 'Times New Roman', serif;
                    line-height: 1.8;
                    color: #1d1d1f;
                    background: #ffffff;
                    padding: 24px 20px 60px;
                    max-width: 680px;
                    margin: 0 auto;
                    -webkit-text-size-adjust: 100%;
                }
                @media (prefers-color-scheme: dark) {
                    body { background: #1c1c1e; color: #f5f5f7; }
                    a { color: #64d2ff; }
                    .meta { color: #98989d; }
                    .site-name { color: #98989d; }
                }
                .site-name {
                    font-size: 13px;
                    color: #86868b;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 12px;
                }
                h1 {
                    font-size: 28px;
                    line-height: 1.2;
                    font-weight: 700;
                    margin-bottom: 16px;
                    letter-spacing: -0.5px;
                }
                .meta {
                    font-size: 14px;
                    color: #86868b;
                    margin-bottom: 32px;
                    padding-bottom: 20px;
                    border-bottom: 1px solid #d2d2d7;
                }
                .content {
                    font-size: 19px;
                    line-height: 1.75;
                }
                .content p { margin-bottom: 1.2em; }
                .content img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                .content h2, .content h3 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                .content a { color: #0066cc; text-decoration: none; }
                .content blockquote {
                    border-left: 3px solid #d2d2d7;
                    padding-left: 16px;
                    margin: 1em 0;
                    color: #6e6e73;
                    font-style: italic;
                }
                .content ul, .content ol { padding-left: 24px; margin-bottom: 1em; }
                .content li { margin-bottom: 0.5em; }
                .content pre, .content code {
                    font-family: 'SF Mono', Menlo, monospace;
                    font-size: 15px;
                    background: #f5f5f7;
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                .content pre {
                    padding: 16px;
                    overflow-x: auto;
                    margin: 1em 0;
                }
            </style>
        </head>
        <body>
            <div class="site-name">\(siteName)</div>
            <h1>\(title)</h1>
            <div class="meta">
                \(author.isEmpty ? "" : "<span>\(author)</span> &middot; ")
                \(date.isEmpty ? "" : "<span>\(date)</span> &middot; ")
                <span>\(readTime) min read</span>
            </div>
            <div class="content">\(content)</div>
        </body>
        </html>
        """
    }
}
