import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var liveActivity: LiveActivityController
    @EnvironmentObject var biometrics: BiometricService

    @State private var showLogoutConfirm = false
    @State private var shareLogURL: URL?

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    section(l.t("settings.theme")) { themeSection }
                    section(l.t("settings.language")) { languageSection }
                    section(l.t("settings.font")) { fontSection }
                    section(l.t("settings.delays")) { delaySection }
                    section("UX") { uxSection }
                    section("Anti-flood") { antiFloodSection }
                    section("Live Activity") { liveActivitySection }
                    section("Безопасность") { securitySection }
                    section("Уведомления") { notificationsSection }
                    section(l.t("settings.developer")) { developerSection }
                    section(l.t("settings.about")) { aboutSection }
                    section(l.t("settings.danger")) { dangerSection }
                    Spacer(minLength: 24)
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .alert(l.t("settings.logout_all"), isPresented: $showLogoutConfirm) {
            Button(l.t("common.cancel"), role: .cancel) {}
            Button(l.t("settings.logout_all"), role: .destructive) {
                manager.logoutAll()
            }
        } message: {
            Text(l.t("accounts.delete.confirm"))
        }
        .sheet(item: Binding(
            get: { shareLogURL.map { ShareItem(url: $0) } },
            set: { _ in shareLogURL = nil }
        )) { item in
            ActivityView(activityItems: [item.url])
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.textTertiary)
                .textCase(.uppercase)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
        }
    }

    private var themeSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AppThemeKind.allCases) { kind in
                    Button {
                        settings.theme = kind
                        if settings.haptic { UISelectionFeedbackGenerator().selectionChanged() }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(kind.background)
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(settings.theme == kind ? kind.accent : AppTheme.separator,
                                                  lineWidth: settings.theme == kind ? 3 : 1)
                                Circle().fill(kind.accent).frame(width: 18, height: 18)
                            }
                            .frame(width: 78, height: 56)
                            Text(kind.displayName)
                                .font(AppTheme.body(11))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var languageSection: some View {
        VStack(spacing: 8) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    settings.language = lang
                    if settings.haptic { UISelectionFeedbackGenerator().selectionChanged() }
                } label: {
                    HStack {
                        Text(lang.displayName).font(AppTheme.headline(15)).foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if settings.language == lang {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(settings.theme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                if lang != AppLanguage.allCases.last { Divider().background(AppTheme.separator) }
            }
        }
    }

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $settings.font) {
                ForEach(AppFontKind.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(l.t("settings.font_size"))
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(String(format: "%+.0f", settings.fontSizeOffset))
                    .font(AppTheme.mono(12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Slider(value: $settings.fontSizeOffset, in: -2...4, step: 1)
                .tint(settings.theme.accent)
        }
    }

    private var delaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(l.t("bulk.delay")).font(AppTheme.body(13)).foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(l.t("bulk.delay.format", settings.bulkDelaySeconds))
                    .font(AppTheme.mono(12)).foregroundStyle(AppTheme.textSecondary)
            }
            Slider(value: $settings.bulkDelaySeconds, in: 0...10, step: 0.1)
                .tint(settings.theme.accent)
        }
    }

    private var uxSection: some View {
        VStack(spacing: 0) {
            Toggle(l.t("settings.show_splash"), isOn: $settings.showSplash)
                .tint(settings.theme.accent)
            Divider().background(AppTheme.separator).padding(.vertical, 6)
            Toggle(l.t("settings.haptic"), isOn: $settings.haptic)
                .tint(settings.theme.accent)
        }
    }

    private var antiFloodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Smart retry on FloodWait", isOn: $settings.smartRetryOnFlood)
                .tint(settings.theme.accent)
            HStack {
                Text("Макс. попыток").font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Stepper(value: $settings.maxFloodRetries, in: 0...5) {
                    Text("\(settings.maxFloodRetries)").font(AppTheme.mono(12))
                }.labelsHidden()
            }
            HStack {
                Text("Fallback (с)").font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Stepper(value: $settings.floodFallbackSeconds, in: 5...300, step: 5) {
                    Text("\(settings.floodFallbackSeconds)").font(AppTheme.mono(12))
                }.labelsHidden()
            }
        }
    }

    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Включить Live Activity", isOn: $settings.liveActivityEnabled)
                .tint(settings.theme.accent)
                .onChange(of: settings.liveActivityEnabled) { newValue in
                    Task {
                        if newValue {
                            await liveActivity.start(label: settings.liveActivityText)
                        } else {
                            await liveActivity.stop()
                        }
                    }
                }
            ThemedTextField(title: "Текст под чёлкой",
                             text: $settings.liveActivityText,
                             placeholder: "@MaksimXyila")
                .onChange(of: settings.liveActivityText) { newValue in
                    Task { await liveActivity.update(label: newValue) }
                }
            HStack {
                Text("Статус")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(liveActivity.isRunning ? "running" : "stopped")
                    .font(AppTheme.mono(12))
                    .foregroundStyle(liveActivity.isRunning ? AppTheme.success : AppTheme.textTertiary)
            }
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.biometricLock) {
                Text("\(biometrics.biometryName) при запуске")
            }
            .tint(settings.theme.accent)
            .disabled(!biometrics.isAvailable)
            if !biometrics.isAvailable {
                Text("Биометрия недоступна на этом устройстве")
                    .font(AppTheme.body(11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Уведомлять о завершении bulk", isOn: $settings.notifyOnBulkCompletion)
                .tint(settings.theme.accent)
        }
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("@MaksimXyila")
                .font(AppTheme.headline(16))
                .foregroundStyle(settings.theme.accent)
            Text("github.com/tt2819ais-arch/tg-multiacc-ios")
                .font(AppTheme.mono(11))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var aboutSection: some View {
        HStack {
            Text(l.t("settings.version"))
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("\(TDConfig.appVersion)")
                .font(AppTheme.mono(12))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 8) {
            Button {
                if let url = logger.makeShareableSnapshot() { shareLogURL = url }
            } label: {
                Label(l.t("settings.export_logs"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button { logger.clear() } label: {
                Label(l.t("settings.clear_logs"), systemImage: "trash")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button { showLogoutConfirm = true } label: {
                Label(l.t("settings.logout_all"), systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(PrimaryButtonStyle(fill: AppTheme.danger))
        }
    }
}

private struct ShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
