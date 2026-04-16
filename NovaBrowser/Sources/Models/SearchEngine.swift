// SearchEngine.swift
// NovaBrowser - Search engine configuration

import Foundation

enum SearchEngine: String, CaseIterable, Codable, Identifiable {
    case google
    case duckDuckGo
    case bing
    case yahoo
    case startpage
    case brave
    case ecosia
    case qwant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: return "Google"
        case .duckDuckGo: return "DuckDuckGo"
        case .bing: return "Bing"
        case .yahoo: return "Yahoo"
        case .startpage: return "Startpage"
        case .brave: return "Brave Search"
        case .ecosia: return "Ecosia"
        case .qwant: return "Qwant"
        }
    }

    var searchURLTemplate: String {
        switch self {
        case .google: return "https://www.google.com/search?q=%s"
        case .duckDuckGo: return "https://duckduckgo.com/?q=%s"
        case .bing: return "https://www.bing.com/search?q=%s"
        case .yahoo: return "https://search.yahoo.com/search?p=%s"
        case .startpage: return "https://www.startpage.com/do/dsearch?query=%s"
        case .brave: return "https://search.brave.com/search?q=%s"
        case .ecosia: return "https://www.ecosia.org/search?q=%s"
        case .qwant: return "https://www.qwant.com/?q=%s"
        }
    }

    var suggestionsURLTemplate: String? {
        switch self {
        case .google: return "https://suggestqueries.google.com/complete/search?client=firefox&q=%s"
        case .duckDuckGo: return "https://duckduckgo.com/ac/?q=%s&type=list"
        case .bing: return "https://api.bing.com/osjson.aspx?query=%s"
        case .yahoo: return "https://search.yahoo.com/sugg/gossip/gossip-us-ura/?output=fxjson&command=%s"
        case .brave: return "https://search.brave.com/api/suggest?q=%s"
        default: return nil
        }
    }

    var iconName: String {
        switch self {
        case .google: return "g.circle.fill"
        case .duckDuckGo: return "shield.checkered"
        case .bing: return "b.circle.fill"
        case .yahoo: return "y.circle.fill"
        case .startpage: return "lock.shield"
        case .brave: return "lion.fill"
        case .ecosia: return "leaf.fill"
        case .qwant: return "q.circle.fill"
        }
    }

    func searchURL(for query: String) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let urlString = searchURLTemplate.replacingOccurrences(of: "%s", with: encoded)
        return URL(string: urlString)
    }

    func suggestionsURL(for query: String) -> URL? {
        guard let template = suggestionsURLTemplate,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let urlString = template.replacingOccurrences(of: "%s", with: encoded)
        return URL(string: urlString)
    }
}
