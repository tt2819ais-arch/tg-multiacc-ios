import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var manager: AccountManager
    @State private var splashDone: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            MainTabs()
                .opacity(splashDone || !settings.showSplash ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: splashDone)

            if !splashDone && settings.showSplash {
                SplashView { splashDone = true }
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .tint(settings.theme.accent)
        .onAppear {
            if !settings.showSplash { splashDone = true }
        }
    }
}

private struct MainTabs: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger

    var l: L10n { settings.l10n }

    var body: some View {
        TabView {
            NavigationStack {
                AccountsListView()
            }
            .tabItem { Label(l.t("tab.accounts"), systemImage: "person.2.fill") }

            NavigationStack {
                BulkActionsView()
            }
            .tabItem { Label(l.t("tab.bulk"), systemImage: "bolt.fill") }

            NavigationStack {
                LogsView()
            }
            .tabItem { Label(l.t("tab.logs"), systemImage: "doc.text.magnifyingglass") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(l.t("tab.settings"), systemImage: "gearshape.fill") }
        }
        .tint(settings.theme.accent)
    }
}
