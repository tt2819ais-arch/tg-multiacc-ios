import SwiftUI

@main
struct TGMultiAccApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var logger = AppLogger.shared
    @StateObject private var manager = AccountManager()
    @StateObject private var templates = TemplatesStore()
    @StateObject private var schedule = ScheduleStore()
    @StateObject private var liveActivity = LiveActivityController.shared
    @StateObject private var biometrics = BiometricService()
    @StateObject private var scheduleRunner = ScheduleRunner()

    init() {
        // Pre-warm haptic generators so the first vibration after launch
        // doesn't have a noticeable delay.
        Haptics.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(logger)
                .environmentObject(manager)
                .environmentObject(templates)
                .environmentObject(schedule)
                .environmentObject(liveActivity)
                .environmentObject(biometrics)
                .preferredColorScheme(settings.theme.isLight ? .light : .dark)
                .tint(settings.theme.accent)
                .dynamicTypeSize(.medium ... .accessibility2)
                .font(AppTheme.body(15 + CGFloat(settings.fontSizeOffset))
                        .leading(.standard))
                .task {
                    // Wire haptic gating to the live setting so toggling the
                    // switch in Settings takes effect immediately.
                    Haptics.enabledProvider = { [weak settings] in
                        settings?.hapticsEnabled ?? true
                    }
                    scheduleRunner.bind(manager: manager,
                                         settings: settings,
                                         schedule: schedule)
                    await NotificationService.shared.requestAuthorizationIfNeeded()
                    liveActivity.refreshAuthorizationStatus()
                    if settings.liveActivityEnabled {
                        await liveActivity.start(label: settings.liveActivityText)
                    }
                }
        }
    }
}
