# NovaBrowser

**The Ultimate iOS Browser** - Blazing fast, privacy-first, with CyberKit-enhanced WebKit engine support for maximum compatibility across all iOS versions.

## Downloads

Get the latest build from [GitHub Releases](../../releases) or trigger a build from [Actions](../../actions).

| File | Description | Install Method |
|------|-------------|----------------|
| `NovaBrowser.ipa` | Standard unsigned IPA | AltStore, Sideloadly, Scarlet, Feather |
| `NovaBrowser.tipa` | TrollStore IPA | TrollStore (permanent, no revokes) |

## Features

### Core Browser
- **Blazing Fast Engine** - Optimized WKWebView with performance tuning
- **CyberKit Enhanced** - On jailbroken devices, benefits from CyberKit's backported modern WebKit engine bringing modern web standards to older iOS
- **Smart Address Bar** - Combined URL/search bar with auto-suggestions from bookmarks, history, and search engines
- **Tab Management** - Card-based tab switcher with screenshots, unlimited tabs, drag-to-reorder
- **Private Browsing** - Isolated private browsing mode with separate process pool

### Content
- **Built-in Ad Blocker** - EasyList + EasyPrivacy + Peter Lowe's tracking list with 50+ ad network domains blocked, CSS element hiding, and MutationObserver for dynamic ads
- **Reader Mode** - Clean article extraction with typography optimized for reading
- **Force Dark Mode** - Applies dark theme to any website using CSS filter inversion
- **Find in Page** - Native iOS 16+ find or JavaScript fallback for older versions
- **Desktop Site Request** - Switch user agent to request desktop versions

### Organization
- **Bookmarks** - Full bookmark management with folders, favorites, and reading list
- **History** - Sectioned browsing history (Today, Yesterday, This Week, etc.) with search
- **Download Manager** - File downloads with pause/resume/retry, organized by status

### Privacy & Security
- **HTTPS Upgrade** - Automatically upgrades HTTP to HTTPS
- **Do Not Track** - Sends DNT header
- **Third-Party Cookie Blocking** - Optional blocking of cross-site cookies
- **Fraudulent Website Warning** - Security warnings for known malicious sites
- **Content Blockers** - WKContentRuleList-based blocking compiled from filter lists

### Customization
- **8 Search Engines** - Google, DuckDuckGo, Bing, Yahoo, Startpage, Brave, Ecosia, Qwant
- **Theme System** - Light/Dark/System with custom accent color picker
- **Font Size Control** - Adjustable page font size (50%-200%)
- **Performance Tuning** - Configurable cache size, prefetching, hardware acceleration

### Technical
- **Context Menus** - Long-press on links for Open in New Tab, Copy, Share, Download, Bookmark
- **JavaScript Dialogs** - Full support for alert(), confirm(), prompt() with origin display
- **HTTP Authentication** - Username/password dialogs for protected sites
- **Media Permissions** - Camera/microphone permission requests per-site
- **URL Scheme Handling** - Registers as HTTP/HTTPS handler, handles tel:/mailto:/sms:
- **State Persistence** - Saves and restores tabs, bookmarks, history across app launches
- **Scroll-to-Hide** - Toolbar auto-hides on scroll for more content area

## Architecture

```
NovaBrowser/
├── Sources/
│   ├── App/
│   │   ├── NovaBrowserApp.swift      # App entry point, lifecycle
│   │   └── AppState.swift            # Central state management (tabs, navigation)
│   ├── Models/
│   │   ├── BrowserTab.swift          # Tab model with WKWebView lifecycle
│   │   ├── Bookmark.swift            # Bookmark & folder models
│   │   ├── HistoryItem.swift         # History entry model
│   │   ├── DownloadItem.swift        # Download tracking model
│   │   └── SearchEngine.swift        # 8 search engine configurations
│   ├── Views/
│   │   ├── Browser/
│   │   │   ├── MainBrowserView.swift     # Main browser chrome
│   │   │   ├── WebViewContainer.swift    # WKWebView wrapper + delegates
│   │   │   ├── AddressBar.swift          # Smart address bar + suggestions
│   │   │   ├── NewTabPageView.swift      # New tab page with favorites
│   │   │   └── FindInPageBar.swift       # Find in page + error overlay
│   │   ├── Tabs/
│   │   │   └── TabSwitcherView.swift     # Card-based tab grid
│   │   ├── Settings/
│   │   │   └── SettingsView.swift        # Full settings panel
│   │   ├── Bookmarks/
│   │   │   └── BookmarksView.swift       # Bookmark manager + editor
│   │   ├── History/
│   │   │   └── HistoryView.swift         # Sectioned history browser
│   │   └── Downloads/
│   │       └── DownloadsView.swift       # Download manager UI
│   ├── Managers/
│   │   ├── SettingsManager.swift     # UserDefaults-backed settings
│   │   ├── ThemeManager.swift        # Theme & appearance control
│   │   ├── BookmarkManager.swift     # Bookmark CRUD & persistence
│   │   ├── HistoryManager.swift      # History tracking & sections
│   │   └── DownloadManager.swift     # Download lifecycle management
│   ├── Services/
│   │   ├── AdBlocker/
│   │   │   └── AdBlockManager.swift  # Content blocking engine
│   │   ├── Storage/
│   │   │   └── StorageManager.swift  # File system & cache management
│   │   └── Networking/
│   │       └── SearchSuggestionsService.swift  # Search autocomplete
│   └── Extensions/
│       ├── URLHelper.swift           # URL parsing & resolution
│       ├── UserAgentManager.swift    # User agent strings
│       ├── ReaderModeScripts.swift   # Article extraction JS
│       └── DarkModeScripts.swift     # Dark mode CSS injection
├── Resources/
│   └── Assets.xcassets/              # App icons and assets
├── Info.plist                        # App configuration
└── NovaBrowser.entitlements          # App entitlements
```

## Compatibility

| iOS Version | Support Level | Notes |
|-------------|--------------|-------|
| iOS 15.0+ | Full | All features available |
| iOS 14.0 | Good | Missing some iOS 15+ APIs, graceful fallback |
| iOS 12-13 | Via CyberKit | Requires jailbreak + CyberKit for modern web standards |

## CyberKit Integration

NovaBrowser is designed to work seamlessly with [CyberKit](https://github.com/CyberKitGroup/CyberKit), which is a backport of modern WebKit to older iOS versions:

- On **jailbroken devices** with CyberKit installed, the system WebKit frameworks are replaced with newer versions, automatically improving NovaBrowser's rendering capabilities
- On **stock iOS 15+**, NovaBrowser uses the native WebKit engine with all available optimizations
- On **iOS 17.4+ (EU)**, future versions will support BrowserEngineKit for true alternative engines

## Building

### GitHub Actions (Recommended)
1. Fork this repository
2. Go to Actions tab
3. Run "Build NovaBrowser IPA & TIPA" workflow
4. Download artifacts (IPA and TIPA)

### Local Build
```bash
# Clone
git clone https://github.com/user/NovaBrowser.git
cd NovaBrowser

# Build for device (unsigned)
xcodebuild -project NovaBrowser.xcodeproj \
  -scheme NovaBrowser -configuration Release \
  -sdk iphoneos \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=NO build

# Create IPA
mkdir Payload
cp -r build/Build/Products/Release-iphoneos/NovaBrowser.app Payload/
zip -r NovaBrowser.ipa Payload/
```

### Creating Tagged Release
```bash
git tag v1.0.0
git push origin v1.0.0
# GitHub Actions will automatically create a release with IPA and TIPA
```

## Installation

### TrollStore (Permanent)
1. Download `NovaBrowser.tipa`
2. Open in TrollStore
3. Tap Install - done! No revokes, permanent.

### AltStore / Sideloadly
1. Download `NovaBrowser.ipa`
2. Open in AltStore or Sideloadly
3. Sign and install
4. Refresh every 7 days (AltStore auto-refreshes)

## Technical Details

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum Deployment**: iOS 15.0
- **Engine**: WKWebView (WebKit) with CyberKit enhancement support
- **Bundle ID**: com.novabrowser.app
- **No dependencies**: Zero third-party Swift packages - pure Apple frameworks only
- **Binary size**: ~2MB (app binary only, no bloat)

## License

MIT License - See LICENSE file for details.
