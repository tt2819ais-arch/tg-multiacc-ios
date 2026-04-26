import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var biometrics: BiometricService
    @State private var splashDone: Bool = false
    @State private var showingOnboarding: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            if needsLock && !biometrics.isUnlocked {
                LockGateView()
                    .transition(.opacity)
                    .zIndex(3)
            } else {
                MainTabs()
                    .opacity(splashDone || !shouldShowSplash ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: splashDone)
                    .overlay {
                        if showingOnboarding {
                            OnboardingView { showingOnboarding = false; settings.onboardingCompleted = true }
                                .transition(.opacity)
                                .zIndex(4)
                        }
                    }
            }

            if !splashDone && shouldShowSplash && !needsLock {
                SplashView { splashDone = true }
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .preferredColorScheme(settings.theme.isLight ? .light : .dark)
        .tint(settings.theme.accent)
        .onAppear {
            if !shouldShowSplash { splashDone = true }
            if !settings.onboardingCompleted && !needsLock {
                // Defer the first-launch tutorial until after the splash so it
                // fades in over the actual UI rather than over a black screen.
                Task {
                    try? await Task.sleep(nanoseconds: 1_900_000_000)
                    showingOnboarding = true
                }
            }
        }
    }

    private var needsLock: Bool {
        settings.lockMode.requiresLock && (settings.lockMode == .pin || biometrics.systemBiometricsAvailable || biometrics.hasPin)
    }

    private var shouldShowSplash: Bool {
        settings.showSplash && settings.splashStyle != .off
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
