import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var biometrics: BiometricService
    @State private var splashDone: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            if biometricsRequired && !biometrics.isUnlocked {
                BiometricLockView()
                    .transition(.opacity)
                    .zIndex(3)
            } else {
                MainTabs()
                    .opacity(splashDone || !settings.showSplash ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: splashDone)
            }

            if !splashDone && settings.showSplash && !biometricsRequired {
                SplashView { splashDone = true }
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .tint(settings.theme.accent)
        .onAppear {
            if !settings.showSplash { splashDone = true }
            if biometricsRequired && !biometrics.isUnlocked {
                Task { await biometrics.authenticate(reason: "Разблокируй TG MULTIACC") }
            }
        }
    }

    private var biometricsRequired: Bool {
        settings.biometricLock && biometrics.isAvailable
    }
}

private struct BiometricLockView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var biometrics: BiometricService

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: biometrics.biometryType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(settings.theme.accent)
                Text("TG MULTIACC")
                    .font(AppTheme.title(28))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Заблокировано")
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.textSecondary)
                Button("Разблокировать с \(biometrics.biometryName)") {
                    Task { await biometrics.authenticate(reason: "Разблокируй TG MULTIACC") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                if let err = biometrics.lastError {
                    Text(err).font(AppTheme.body(12)).foregroundStyle(AppTheme.danger)
                }
            }
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
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

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
