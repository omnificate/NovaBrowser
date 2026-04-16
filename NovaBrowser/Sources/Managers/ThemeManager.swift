// ThemeManager.swift
// NovaBrowser - Theme and appearance management

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .system
    @AppStorage("forceDarkMode") var forceDarkMode: Bool = false
    @AppStorage("accentColorHex") var accentColorHex: String = "#007AFF"

    var preferredColorScheme: ColorScheme? {
        switch selectedTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }

    var accentColorBinding: Binding<Color> {
        Binding(
            get: { self.accentColor },
            set: { newColor in
                self.accentColorHex = newColor.hexString ?? "#007AFF"
            }
        )
    }

    var backgroundColor: Color {
        Color(.systemBackground)
    }

    var toolbarColor: Color {
        Color(.systemBackground)
    }

    private init() {}
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components.count > 1 ? components[1] * 255 : components[0] * 255)
        let b = Int(components.count > 2 ? components[2] * 255 : components[0] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
