import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var biometrics: BiometricService
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashDone: Bool = false
    @State private var showingOnboarding: Bool = false
    @State private var lastBackgroundedAt: Date? = nil

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            if needsLock && !biometrics.isUnlocked {
                LockGateView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(3)
            } else {
                MainTabs()
                    .opacity(splashDone || !shouldShowSplash ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.35), value: splashDone)
                    .overlay {
                        if showingOnboarding {
                            OnboardingView { finishOnboarding() }
                                .transition(.opacity)
                                .zIndex(4)
                        }
                    }
            }

            if !splashDone && shouldShowSplash && !needsLock {
                SplashView { withAnimation(.easeOut(duration: 0.35)) { splashDone = true } }
                    .transition(.opacity)
                    .zIndex(2)
            }

            // In-app status pill drawn over everything except splash + lock.
            // We use a custom overlay because real ActivityKit Live Activities
            // do not render inside the running app on devices without Dynamic
            // Island (iPhone 11/12/13).
            if settings.liveActivityEnabled && splashDone
                && !showingOnboarding
                && !(needsLock && !biometrics.isUnlocked) {
                StatusPillView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(5)
                    .allowsHitTesting(true)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: biometrics.isUnlocked)
        .preferredColorScheme(settings.theme.isLight ? .light : .dark)
        .tint(settings.theme.accent)
        .onAppear {
            // Skip the splash entirely when the lock screen is going to take
            // its place — otherwise the lock dismisses to a 0-opacity main
            // view (because splashDone never flipped) and looks like a hang.
            if !shouldShowSplash || needsLock { splashDone = true }
            if !settings.onboardingCompleted && !needsLock {
                Task {
                    try? await Task.sleep(nanoseconds: 1_900_000_000)
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.35)) { showingOnboarding = true }
                    }
                }
            }
        }
        .onChange(of: biometrics.isUnlocked) { unlocked in
            if unlocked && !settings.onboardingCompleted {
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.35)) { showingOnboarding = true }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhase(phase)
        }
    }

    /// Re-lock the app when it has been in the background for more than a few
    /// seconds. This mirrors how banking / messenger apps behave: a quick
    /// notification check doesn't force re-auth, but actually leaving the app
    /// does.
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            if biometrics.isUnlocked {
                lastBackgroundedAt = Date()
            }
        case .active:
            if let last = lastBackgroundedAt,
               Date().timeIntervalSince(last) > 15,
               settings.lockMode.requiresLock {
                biometrics.lock()
            }
            lastBackgroundedAt = nil
        @unknown default:
            break
        }
    }

    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingOnboarding = false
        }
        settings.onboardingCompleted = true
        Haptics.success()
    }

    private var needsLock: Bool {
        settings.lockMode.requiresLock
            && (settings.lockMode == .pin
                || biometrics.systemBiometricsAvailable
                || biometrics.hasPin)
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
