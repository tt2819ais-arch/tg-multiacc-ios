import Foundation
import SwiftUI

enum AppThemeKind: String, CaseIterable, Identifiable, Codable {
    case midnight, graphite, ocean, plum, forest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .ocean:    return "Ocean"
        case .plum:     return "Plum"
        case .forest:   return "Forest"
        }
    }

    var background: Color {
        switch self {
        case .midnight: return Color(red: 0.04, green: 0.04, blue: 0.05)
        case .graphite: return Color(red: 0.07, green: 0.07, blue: 0.08)
        case .ocean:    return Color(red: 0.03, green: 0.06, blue: 0.10)
        case .plum:     return Color(red: 0.07, green: 0.04, blue: 0.10)
        case .forest:   return Color(red: 0.03, green: 0.07, blue: 0.05)
        }
    }

    var surface: Color {
        switch self {
        case .midnight: return Color(red: 0.09, green: 0.09, blue: 0.11)
        case .graphite: return Color(red: 0.13, green: 0.13, blue: 0.15)
        case .ocean:    return Color(red: 0.06, green: 0.10, blue: 0.16)
        case .plum:     return Color(red: 0.13, green: 0.07, blue: 0.18)
        case .forest:   return Color(red: 0.06, green: 0.13, blue: 0.09)
        }
    }

    var accent: Color {
        switch self {
        case .midnight: return Color(red: 0.15, green: 0.55, blue: 1.00)
        case .graphite: return Color(red: 1.00, green: 1.00, blue: 1.00)
        case .ocean:    return Color(red: 0.20, green: 0.80, blue: 1.00)
        case .plum:     return Color(red: 0.85, green: 0.30, blue: 1.00)
        case .forest:   return Color(red: 0.20, green: 0.95, blue: 0.55)
        }
    }
}

enum AppFontKind: String, CaseIterable, Identifiable, Codable {
    case rounded, sans, mono, serif

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: return "Rounded"
        case .sans:    return "Sans"
        case .mono:    return "Mono"
        case .serif:   return "Serif"
        }
    }

    var design: Font.Design {
        switch self {
        case .rounded: return .rounded
        case .sans:    return .default
        case .mono:    return .monospaced
        case .serif:   return .serif
        }
    }
}

/// User-tunable preferences. Persisted to UserDefaults.
final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var theme: AppThemeKind { didSet { defaults.set(theme.rawValue, forKey: "settings.theme") } }
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "settings.lang") } }
    @Published var font: AppFontKind { didSet { defaults.set(font.rawValue, forKey: "settings.font") } }
    @Published var fontSizeOffset: Double { didSet { defaults.set(fontSizeOffset, forKey: "settings.fontOff") } }
    @Published var bulkDelaySeconds: Double { didSet { defaults.set(bulkDelaySeconds, forKey: "settings.bulkDelay") } }
    @Published var showSplash: Bool { didSet { defaults.set(showSplash, forKey: "settings.splash") } }
    @Published var haptic: Bool { didSet { defaults.set(haptic, forKey: "settings.haptic") } }

    init() {
        self.theme = AppThemeKind(rawValue: defaults.string(forKey: "settings.theme") ?? "") ?? .midnight
        self.language = AppLanguage(rawValue: defaults.string(forKey: "settings.lang") ?? "")
            ?? Self.systemDefaultLanguage()
        self.font = AppFontKind(rawValue: defaults.string(forKey: "settings.font") ?? "") ?? .rounded
        self.fontSizeOffset = defaults.object(forKey: "settings.fontOff") as? Double ?? 0
        self.bulkDelaySeconds = defaults.object(forKey: "settings.bulkDelay") as? Double ?? 1.5
        self.showSplash = defaults.object(forKey: "settings.splash") as? Bool ?? true
        self.haptic = defaults.object(forKey: "settings.haptic") as? Bool ?? true
    }

    var l10n: L10n { L10n(language: language) }

    private static func systemDefaultLanguage() -> AppLanguage {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        switch lang {
        case "ru": return .ru
        case "uk": return .uk
        default:   return .en
        }
    }
}

/// Root environment carrying shared services to the whole view hierarchy.
final class AppEnvironment: ObservableObject {
    let settings: SettingsStore
    let logger: AppLogger
    let accounts: AccountManager

    @Published var firstLaunchSplashDone: Bool = false

    init(settings: SettingsStore, logger: AppLogger, accounts: AccountManager) {
        self.settings = settings
        self.logger = logger
        self.accounts = accounts
    }
}
