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
    @State private var showPinSetup = false
    @State private var showRemovePinAlert = false

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    section(l.t("settings.theme"))    { themeSection }
                    section("Внешний вид")            { appearanceSection }
                    section(l.t("settings.language")) { languageSection }
                    section(l.t("settings.font"))     { fontSection }
                    section(l.t("settings.delays"))   { delaySection }
                    section("UX")                     { uxSection }
                    section("Anti-flood")             { antiFloodSection }
                    section("Live Activity")          { liveActivitySection }
                    section("Безопасность")           { securitySection }
                    section("Уведомления")            { notificationsSection }
                    section("Обучение")               { onboardingSection }
                    section(l.t("settings.developer")) { developerSection }
                    section(l.t("settings.about"))     { aboutSection }
                    section(l.t("settings.danger"))    { dangerSection }
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
                Haptics.warning()
                manager.logoutAll()
            }
        } message: {
            Text(l.t("accounts.delete.confirm"))
        }
        .alert("Удалить PIN?", isPresented: $showRemovePinAlert) {
            Button("Отменить", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                biometrics.clearPin()
                if settings.lockMode == .pin || settings.lockMode == .biometricThenPin {
                    settings.lockMode = biometrics.systemBiometricsAvailable ? .biometric : .off
                }
                Haptics.warning()
            }
        }
        .sheet(item: Binding(
            get: { shareLogURL.map { ShareItem(url: $0) } },
            set: { _ in shareLogURL = nil }
        )) { item in
            ActivityView(activityItems: [item.url])
        }
        .sheet(isPresented: $showPinSetup) {
            PinSetupView()
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
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppThemeKind.allCases) { kind in
                        Button {
                            settings.theme = kind
                            Haptics.selection()
                        } label: {
                            ThemeCard(kind: kind, isSelected: settings.theme == kind)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            HStack {
                Image(systemName: "paintpalette")
                    .foregroundStyle(AppTheme.textTertiary)
                Text(settings.theme.subtitle)
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Плотность списков")
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.textTertiary)
            Picker("Density", selection: $settings.density) {
                ForEach(AppDensity.allCases) { d in
                    Text(d.displayName).tag(d)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.density) { _ in Haptics.selection() }

            Toggle("Компактные кнопки массовых действий",
                   isOn: $settings.compactBulkButtons)
                .tint(settings.theme.accent)
                .onChange(of: settings.compactBulkButtons) { _ in Haptics.selection() }

            Picker("Заставка", selection: $settings.splashStyle) {
                ForEach(SplashStyle.allCases) { s in
                    Text(s.displayName).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.splashStyle) { _ in Haptics.selection() }
        }
    }

    private var languageSection: some View {
        VStack(spacing: 8) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    settings.language = lang
                    Haptics.selection()
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
            .onChange(of: settings.font) { _ in Haptics.selection() }

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
            Toggle("Тактильные отклики (вибро)", isOn: $settings.hapticsEnabled)
                .tint(settings.theme.accent)
                .onChange(of: settings.hapticsEnabled) { newValue in
                    if newValue { Haptics.medium() }
                }
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

            // Diagnostic line so the user can see immediately whether iOS will
            // actually surface the activity or has silently denied permission.
            HStack {
                Text("Разрешено в системе")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(liveActivity.systemAllowsActivities ? "да" : "нет")
                    .font(AppTheme.mono(12))
                    .foregroundStyle(liveActivity.systemAllowsActivities ? AppTheme.success : AppTheme.danger)
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
            if let err = liveActivity.lastError {
                Text(err)
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.danger)
            }
            if !liveActivity.systemAllowsActivities {
                Text("Включи Live Activity в Настройки → Уведомления → TG MULTIACC, или в самих настройках iOS («Live Activities»).")
                    .font(AppTheme.body(11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            HStack(spacing: 8) {
                Button {
                    Haptics.medium()
                    Task { await liveActivity.start(label: settings.liveActivityText) }
                } label: {
                    Label("Запустить сейчас", systemImage: "play.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    Haptics.light()
                    Task { await liveActivity.stop() }
                } label: {
                    Label("Стоп", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Способ блокировки")
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.textTertiary)
            Picker("Lock", selection: $settings.lockMode) {
                ForEach(AppLockMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.lockMode) { newValue in
                Haptics.selection()
                handleLockChange(newValue)
            }

            // PIN management.
            if biometrics.hasPin {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(AppTheme.success)
                    Text("PIN установлен")
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button("Изменить") {
                        Haptics.selection()
                        showPinSetup = true
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(settings.theme.accent)
                    Button("Удалить") {
                        Haptics.warning()
                        showRemovePinAlert = true
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.danger)
                }
            } else if settings.lockMode.requiresPin {
                Button {
                    Haptics.medium()
                    showPinSetup = true
                } label: {
                    Label("Задать PIN", systemImage: "number.square")
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            // Status hints.
            if settings.lockMode.requiresBiometric && !biometrics.systemBiometricsAvailable {
                Text("\(biometrics.biometryName) недоступен на этом устройстве — приложение упадёт обратно на PIN или код устройства.")
                    .font(AppTheme.body(11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func handleLockChange(_ mode: AppLockMode) {
        // If the user picked a mode requiring a PIN but hasn't set one yet,
        // jump straight to the PIN setup sheet so we don't end up locking
        // them out on the next launch.
        if mode.requiresPin && !biometrics.hasPin {
            showPinSetup = true
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Уведомлять о завершении bulk", isOn: $settings.notifyOnBulkCompletion)
                .tint(settings.theme.accent)
        }
    }

    private var onboardingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Первое обучение")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(settings.onboardingCompleted ? "пройдено" : "будет показано")
                    .font(AppTheme.mono(12))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Button("Показать обучение заново") {
                Haptics.medium()
                settings.onboardingCompleted = false
            }
            .buttonStyle(SecondaryButtonStyle())
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
                if let url = logger.makeShareableSnapshot() {
                    shareLogURL = url
                    Haptics.light()
                }
            } label: {
                Label(l.t("settings.export_logs"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                logger.clear()
                Haptics.warning()
            } label: {
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

private struct ThemeCard: View {
    let kind: AppThemeKind
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(kind.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? kind.accent : AppTheme.separator,
                                          lineWidth: isSelected ? 3 : 1)
                    )
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(kind.accent).frame(width: 16, height: 16)
                        Capsule()
                            .fill(kind.surfaceElevated)
                            .frame(width: 30, height: 4)
                    }
                    Capsule()
                        .fill(kind.palette.accentSecondary.opacity(0.6))
                        .frame(width: 46, height: 3)
                    Capsule()
                        .fill(kind.surfaceElevated)
                        .frame(width: 38, height: 3)
                }
            }
            .frame(width: 86, height: 60)

            Text(kind.displayName)
                .font(AppTheme.body(11))
                .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
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
