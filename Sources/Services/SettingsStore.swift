import Foundation
import SwiftUI

enum AppThemeKind: String, CaseIterable, Identifiable, Codable {
    case void, slate, ink, sepia, forest, sand, paper

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .void:   return "Void"
        case .slate:  return "Slate"
        case .ink:    return "Ink"
        case .sepia:  return "Sepia"
        case .forest: return "Forest"
        case .sand:   return "Sand"
        case .paper:  return "Paper"
        }
    }

    var subtitle: String {
        switch self {
        case .void:   return "тёмный, по умолчанию"
        case .slate:  return "графит, спокойный"
        case .ink:    return "чёрный, монохром"
        case .sepia:  return "тёплый коричневый"
        case .forest: return "глубокий зелёный"
        case .sand:   return "светлый бежевый"
        case .paper:  return "светлый, чистый"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .void:   return .void
        case .slate:  return .slate
        case .ink:    return .ink
        case .sepia:  return .sepia
        case .forest: return .forest
        case .sand:   return .sand
        case .paper:  return .paper
        }
    }

    // Convenience accessors used throughout the codebase.
    var background: Color  { palette.background }
    var surface: Color     { palette.surface }
    var surfaceElevated: Color { palette.surfaceElevated }
    var accent: Color      { palette.accent }
    var textPrimary: Color { palette.textPrimary }
    var isLight: Bool      { palette.isLight }
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

enum AppLockMode: String, CaseIterable, Identifiable, Codable {
    case off, biometric, pin, biometricThenPin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:               return "Выкл"
        case .biometric:         return "Биометрия"
        case .pin:               return "PIN-код"
        case .biometricThenPin:  return "Биометрия + PIN"
        }
    }

    var requiresPin: Bool {
        self == .pin || self == .biometricThenPin
    }

    var requiresBiometric: Bool {
        self == .biometric || self == .biometricThenPin
    }

    var requiresLock: Bool {
        self != .off
    }
}

enum AppDensity: String, CaseIterable, Identifiable, Codable {
    case compact, regular, spacious

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact:  return "Компактно"
        case .regular:  return "Обычно"
        case .spacious: return "Просторно"
        }
    }

    var rowSpacing: CGFloat {
        switch self {
        case .compact:  return 6
        case .regular:  return 10
        case .spacious: return 16
        }
    }

    var listInsets: CGFloat {
        switch self {
        case .compact:  return 8
        case .regular:  return 12
        case .spacious: return 18
        }
    }
}

/// User-tunable preferences. Persisted to UserDefaults. Whenever
/// `theme` changes, the matching palette is mirrored into `AppTheme.palette`
/// so legacy call sites pick up the new colors automatically.
final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var theme: AppThemeKind {
        didSet {
            defaults.set(theme.rawValue, forKey: "settings.theme")
            AppTheme.palette = theme.palette
        }
    }
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "settings.lang") } }
    @Published var font: AppFontKind { didSet { defaults.set(font.rawValue, forKey: "settings.font") } }
    @Published var fontSizeOffset: Double { didSet { defaults.set(fontSizeOffset, forKey: "settings.fontOff") } }
    @Published var density: AppDensity { didSet { defaults.set(density.rawValue, forKey: "settings.density") } }
    @Published var bulkDelaySeconds: Double { didSet { defaults.set(bulkDelaySeconds, forKey: "settings.bulkDelay") } }
    @Published var showSplash: Bool { didSet { defaults.set(showSplash, forKey: "settings.splash") } }
    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "settings.haptics") } }

    @Published var smartRetryOnFlood: Bool { didSet { defaults.set(smartRetryOnFlood, forKey: "settings.smartRetry") } }
    @Published var maxFloodRetries: Int { didSet { defaults.set(maxFloodRetries, forKey: "settings.maxRetries") } }
    @Published var floodFallbackSeconds: Int { didSet { defaults.set(floodFallbackSeconds, forKey: "settings.floodFallback") } }
    @Published var notifyOnBulkCompletion: Bool { didSet { defaults.set(notifyOnBulkCompletion, forKey: "settings.notifyBulk") } }
    @Published var lockMode: AppLockMode { didSet { defaults.set(lockMode.rawValue, forKey: "settings.lockMode") } }
    @Published var liveActivityEnabled: Bool { didSet { defaults.set(liveActivityEnabled, forKey: "settings.liveActivity") } }
    @Published var liveActivityText: String { didSet { defaults.set(liveActivityText, forKey: "settings.liveActivityText") } }
    @Published var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: "settings.onboardDone") } }
    @Published var splashStyle: SplashStyle { didSet { defaults.set(splashStyle.rawValue, forKey: "settings.splashStyle") } }
    @Published var compactBulkButtons: Bool { didSet { defaults.set(compactBulkButtons, forKey: "settings.compactBulk") } }

    init() {
        let initialTheme = AppThemeKind(rawValue: defaults.string(forKey: "settings.theme") ?? "") ?? .void
        self.theme = initialTheme
        AppTheme.palette = initialTheme.palette

        self.language = AppLanguage(rawValue: defaults.string(forKey: "settings.lang") ?? "")
            ?? Self.systemDefaultLanguage()
        self.font = AppFontKind(rawValue: defaults.string(forKey: "settings.font") ?? "") ?? .rounded
        self.fontSizeOffset = defaults.object(forKey: "settings.fontOff") as? Double ?? 0
        self.density = AppDensity(rawValue: defaults.string(forKey: "settings.density") ?? "") ?? .regular
        self.bulkDelaySeconds = defaults.object(forKey: "settings.bulkDelay") as? Double ?? 1.5
        self.showSplash = defaults.object(forKey: "settings.splash") as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: "settings.haptics") as? Bool ?? true

        self.smartRetryOnFlood = defaults.object(forKey: "settings.smartRetry") as? Bool ?? true
        self.maxFloodRetries = defaults.object(forKey: "settings.maxRetries") as? Int ?? 2
        self.floodFallbackSeconds = defaults.object(forKey: "settings.floodFallback") as? Int ?? 30
        self.notifyOnBulkCompletion = defaults.object(forKey: "settings.notifyBulk") as? Bool ?? true
        self.lockMode = AppLockMode(rawValue: defaults.string(forKey: "settings.lockMode") ?? "") ?? .off
        self.liveActivityEnabled = defaults.object(forKey: "settings.liveActivity") as? Bool ?? false
        self.liveActivityText = defaults.string(forKey: "settings.liveActivityText") ?? "@MaksimXyila"
        self.onboardingCompleted = defaults.object(forKey: "settings.onboardDone") as? Bool ?? false
        self.splashStyle = SplashStyle(rawValue: defaults.string(forKey: "settings.splashStyle") ?? "") ?? .quote
        self.compactBulkButtons = defaults.object(forKey: "settings.compactBulk") as? Bool ?? false
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

enum SplashStyle: String, CaseIterable, Identifiable, Codable {
    case quote, minimal, off

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quote:   return "Цитата в углу"
        case .minimal: return "Минимально"
        case .off:     return "Без заставки"
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
