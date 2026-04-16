// SearchSuggestionsService.swift
// NovaBrowser - Auto-complete search suggestions

import Foundation

final class SearchSuggestionsService {
    private var currentTask: URLSessionDataTask?

    func fetchSuggestions(for query: String, completion: @escaping ([SearchSuggestion]) -> Void) {
        currentTask?.cancel()

        guard !query.isEmpty else {
            completion([])
            return
        }

        var results: [SearchSuggestion] = []

        // Check bookmarks
        let bookmarkMatches = BookmarkManager.shared.allBookmarks
            .filter { $0.title.localizedCaseInsensitiveContains(query) || $0.url.localizedCaseInsensitiveContains(query) }
            .prefix(2)
            .map { SearchSuggestion(text: $0.url, type: .bookmark) }
        results.append(contentsOf: bookmarkMatches)

        // Check history
        let historyMatches = HistoryManager.shared.items
            .filter { $0.matches(query: query) }
            .prefix(2)
            .map { SearchSuggestion(text: $0.url, type: .history) }
        results.append(contentsOf: historyMatches)

        // If looks like URL, add URL suggestion
        if query.contains(".") && !query.contains(" ") {
            let urlText = query.hasPrefix("http") ? query : "https://\(query)"
            results.insert(SearchSuggestion(text: urlText, type: .url), at: 0)
        }

        // Fetch from search engine
        let engine = SettingsManager.shared.searchEngine
        guard let suggestURL = engine.suggestionsURL(for: query) else {
            completion(results)
            return
        }

        currentTask = URLSession.shared.dataTask(with: suggestURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(results) }
                return
            }

            do {
                // Google/DuckDuckGo format: ["query", ["suggestion1", "suggestion2", ...]]
                if let json = try JSONSerialization.jsonObject(with: data) as? [Any],
                   json.count > 1,
                   let suggestions = json[1] as? [String] {
                    let searchSuggestions = suggestions.prefix(5).map {
                        SearchSuggestion(text: $0, type: .search)
                    }
                    results.append(contentsOf: searchSuggestions)
                }
            } catch {
                // Try alternative format
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let suggestions = json.compactMap { $0["phrase"] as? String }.prefix(5).map {
                        SearchSuggestion(text: $0, type: .search)
                    }
                    results.append(contentsOf: suggestions)
                }
            }

            DispatchQueue.main.async { completion(results) }
        }
        currentTask?.resume()
    }
}
