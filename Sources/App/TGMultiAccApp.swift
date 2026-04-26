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
                .preferredColorScheme(.dark)
                .tint(settings.theme.accent)
                .dynamicTypeSize(.medium ... .accessibility2)
                .font(AppTheme.body(15 + CGFloat(settings.fontSizeOffset))
                        .leading(.standard))
                .task {
                    scheduleRunner.bind(manager: manager,
                                         settings: settings,
                                         schedule: schedule)
                    await NotificationService.shared.requestAuthorizationIfNeeded()
                    if settings.liveActivityEnabled {
                        await liveActivity.start(label: settings.liveActivityText)
                    }
                }
        }
    }
}
