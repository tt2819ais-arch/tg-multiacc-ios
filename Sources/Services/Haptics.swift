import UIKit

/// Centralized haptic feedback. Reads `SettingsStore.hapticsEnabled` lazily
/// so toggling the setting takes effect immediately without re-wiring views.
@MainActor
enum Haptics {
    /// Set by `TGMultiAccApp` once the SettingsStore is alive so this enum
    /// can decide whether haptics are currently enabled. Defaults to `true`
    /// before the app boots.
    static var enabledProvider: () -> Bool = { true }

    private static var prepared: Bool = false

    /// Pre-initialize generators to reduce trigger latency. Cheap, called once
    /// on app launch.
    static func prepare() {
        guard !prepared else { return }
        UIImpactFeedbackGenerator(style: .light).prepare()
        UIImpactFeedbackGenerator(style: .medium).prepare()
        UIImpactFeedbackGenerator(style: .heavy).prepare()
        UIImpactFeedbackGenerator(style: .soft).prepare()
        UIImpactFeedbackGenerator(style: .rigid).prepare()
        UINotificationFeedbackGenerator().prepare()
        UISelectionFeedbackGenerator().prepare()
        prepared = true
    }

    static func soft() {
        guard enabledProvider() else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func light() {
        guard enabledProvider() else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabledProvider() else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard enabledProvider() else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func rigid() {
        guard enabledProvider() else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func selection() {
        guard enabledProvider() else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        guard enabledProvider() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabledProvider() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        guard enabledProvider() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
