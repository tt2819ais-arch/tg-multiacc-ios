import SwiftUI

@main
struct TGMultiAccApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var logger = AppLogger.shared
    @StateObject private var manager = AccountManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(logger)
                .environmentObject(manager)
                .preferredColorScheme(.dark)
                .tint(settings.theme.accent)
                .dynamicTypeSize(.medium ... .accessibility2)
                .font(AppTheme.body(15 + CGFloat(settings.fontSizeOffset))
                        .leading(.standard))
        }
    }
}
