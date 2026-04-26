import SwiftUI

/// Full color palette describing every reusable surface in the app.
/// Themes pick a palette in `AppThemeKind.palette`. The currently-active
/// palette is mirrored into `AppTheme.palette` so legacy call sites keep
/// reading the right colors without having to rewrite every view.
struct ThemePalette: Equatable {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let separator: Color
    let accent: Color
    let accentSecondary: Color
    let danger: Color
    let success: Color
    let warning: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let isLight: Bool

    static let void = ThemePalette(
        background: Color(red: 0.04, green: 0.04, blue: 0.05),
        surface: Color(red: 0.09, green: 0.09, blue: 0.11),
        surfaceElevated: Color(red: 0.13, green: 0.13, blue: 0.16),
        separator: Color.white.opacity(0.06),
        accent: Color(red: 0.85, green: 0.85, blue: 0.90),
        accentSecondary: Color(red: 0.55, green: 0.55, blue: 0.62),
        danger: Color(red: 0.85, green: 0.34, blue: 0.34),
        success: Color(red: 0.42, green: 0.72, blue: 0.50),
        warning: Color(red: 0.90, green: 0.74, blue: 0.40),
        textPrimary: Color.white.opacity(0.95),
        textSecondary: Color.white.opacity(0.62),
        textTertiary: Color.white.opacity(0.38),
        isLight: false
    )

    static let slate = ThemePalette(
        background: Color(red: 0.10, green: 0.12, blue: 0.16),
        surface: Color(red: 0.14, green: 0.17, blue: 0.22),
        surfaceElevated: Color(red: 0.18, green: 0.21, blue: 0.27),
        separator: Color.white.opacity(0.08),
        accent: Color(red: 0.55, green: 0.72, blue: 0.92),
        accentSecondary: Color(red: 0.45, green: 0.58, blue: 0.74),
        danger: Color(red: 0.86, green: 0.42, blue: 0.42),
        success: Color(red: 0.45, green: 0.74, blue: 0.55),
        warning: Color(red: 0.92, green: 0.76, blue: 0.42),
        textPrimary: Color(red: 0.94, green: 0.95, blue: 0.97),
        textSecondary: Color(red: 0.70, green: 0.74, blue: 0.80),
        textTertiary: Color(red: 0.50, green: 0.54, blue: 0.60),
        isLight: false
    )

    static let ink = ThemePalette(
        background: Color.black,
        surface: Color(red: 0.07, green: 0.07, blue: 0.07),
        surfaceElevated: Color(red: 0.12, green: 0.12, blue: 0.12),
        separator: Color.white.opacity(0.10),
        accent: Color.white,
        accentSecondary: Color(white: 0.65),
        danger: Color(red: 0.80, green: 0.35, blue: 0.35),
        success: Color(red: 0.55, green: 0.78, blue: 0.55),
        warning: Color(red: 0.92, green: 0.78, blue: 0.42),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.66),
        textTertiary: Color(white: 0.40),
        isLight: false
    )

    static let sepia = ThemePalette(
        background: Color(red: 0.16, green: 0.13, blue: 0.10),
        surface: Color(red: 0.21, green: 0.17, blue: 0.13),
        surfaceElevated: Color(red: 0.27, green: 0.22, blue: 0.17),
        separator: Color(red: 0.45, green: 0.36, blue: 0.26).opacity(0.30),
        accent: Color(red: 0.85, green: 0.66, blue: 0.40),
        accentSecondary: Color(red: 0.66, green: 0.50, blue: 0.30),
        danger: Color(red: 0.84, green: 0.44, blue: 0.36),
        success: Color(red: 0.62, green: 0.74, blue: 0.42),
        warning: Color(red: 0.93, green: 0.74, blue: 0.40),
        textPrimary: Color(red: 0.96, green: 0.92, blue: 0.85),
        textSecondary: Color(red: 0.78, green: 0.72, blue: 0.62),
        textTertiary: Color(red: 0.58, green: 0.52, blue: 0.42),
        isLight: false
    )

    static let forest = ThemePalette(
        background: Color(red: 0.06, green: 0.10, blue: 0.08),
        surface: Color(red: 0.10, green: 0.15, blue: 0.12),
        surfaceElevated: Color(red: 0.14, green: 0.20, blue: 0.16),
        separator: Color.white.opacity(0.07),
        accent: Color(red: 0.50, green: 0.74, blue: 0.55),
        accentSecondary: Color(red: 0.40, green: 0.60, blue: 0.46),
        danger: Color(red: 0.84, green: 0.42, blue: 0.42),
        success: Color(red: 0.50, green: 0.78, blue: 0.55),
        warning: Color(red: 0.93, green: 0.76, blue: 0.40),
        textPrimary: Color(red: 0.94, green: 0.96, blue: 0.94),
        textSecondary: Color(red: 0.70, green: 0.78, blue: 0.72),
        textTertiary: Color(red: 0.48, green: 0.55, blue: 0.50),
        isLight: false
    )

    static let sand = ThemePalette(
        background: Color(red: 0.95, green: 0.92, blue: 0.85),
        surface: Color(red: 0.99, green: 0.96, blue: 0.90),
        surfaceElevated: Color.white,
        separator: Color.black.opacity(0.08),
        accent: Color(red: 0.55, green: 0.40, blue: 0.20),
        accentSecondary: Color(red: 0.70, green: 0.55, blue: 0.30),
        danger: Color(red: 0.78, green: 0.30, blue: 0.30),
        success: Color(red: 0.30, green: 0.62, blue: 0.40),
        warning: Color(red: 0.85, green: 0.62, blue: 0.20),
        textPrimary: Color(red: 0.13, green: 0.10, blue: 0.05),
        textSecondary: Color(red: 0.32, green: 0.28, blue: 0.20),
        textTertiary: Color(red: 0.55, green: 0.50, blue: 0.42),
        isLight: true
    )

    static let paper = ThemePalette(
        background: Color(red: 0.97, green: 0.97, blue: 0.96),
        surface: Color.white,
        surfaceElevated: Color.white,
        separator: Color.black.opacity(0.08),
        accent: Color(red: 0.20, green: 0.40, blue: 0.78),
        accentSecondary: Color(red: 0.40, green: 0.55, blue: 0.85),
        danger: Color(red: 0.78, green: 0.30, blue: 0.30),
        success: Color(red: 0.20, green: 0.60, blue: 0.36),
        warning: Color(red: 0.80, green: 0.55, blue: 0.18),
        textPrimary: Color(red: 0.10, green: 0.10, blue: 0.12),
        textSecondary: Color(red: 0.32, green: 0.32, blue: 0.36),
        textTertiary: Color(red: 0.55, green: 0.55, blue: 0.60),
        isLight: true
    )
}

enum AppTheme {
    /// Mirror of the currently-active palette. `SettingsStore.theme` keeps
    /// this in sync via its didSet observer.
    static var palette: ThemePalette = .void

    static var background: Color        { palette.background }
    static var surface: Color           { palette.surface }
    static var surfaceElevated: Color   { palette.surfaceElevated }
    static var separator: Color         { palette.separator }
    static var accent: Color            { palette.accent }
    static var accentSecondary: Color   { palette.accentSecondary }
    static var danger: Color            { palette.danger }
    static var success: Color           { palette.success }
    static var warning: Color           { palette.warning }
    static var textPrimary: Color       { palette.textPrimary }
    static var textSecondary: Color     { palette.textSecondary }
    static var textTertiary: Color      { palette.textTertiary }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct CardBackground: ViewModifier {
    var color: Color = AppTheme.surface
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func card(_ color: Color = AppTheme.surface) -> some View {
        modifier(CardBackground(color: color))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = AppTheme.accent
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline(16))
            .foregroundStyle(AppTheme.palette.isLight ? Color.white : Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(disabled ? fill.opacity(0.35) : fill)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline(16))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline(16))
            .foregroundStyle(AppTheme.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.danger.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.danger.opacity(0.6), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
