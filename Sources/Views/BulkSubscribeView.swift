import SwiftUI

struct BulkSubscribeView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger

    @State private var target: String = ""

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ThemedTextField(title: l.t("bulk.subscribe.title"),
                                    text: $target,
                                    placeholder: l.t("bulk.subscribe.placeholder"))

                    HStack {
                        Text(l.t("bulk.delay"))
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(l.t("bulk.delay.format", settings.bulkDelaySeconds))
                            .font(AppTheme.mono(12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Slider(value: $settings.bulkDelaySeconds, in: 0...10, step: 0.1)
                        .tint(settings.theme.accent)

                    Button(action: { Task { await run() } }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(l.t("bulk.subscribe.run"))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                    disabled: !canRun))
                    .disabled(!canRun)

                    BulkProgressSection()
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.subscribe.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canRun: Bool {
        !target.trimmingCharacters(in: .whitespaces).isEmpty
            && !manager.readyAccounts.isEmpty
            && !manager.bulkState.isRunning
    }

    private func run() async {
        let value = target
        await manager.runBulk(category: "bulk:subscribe",
                               settings: settings) { acc in
            let title = try await acc.subscribe(to: value)
            return "Subscribed: \(title)"
        }
    }
}

struct BulkProgressSection: View {
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var settings: SettingsStore

    var l: L10n { settings.l10n }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if manager.bulkState.isRunning {
                Text(l.t("bulk.running",
                          manager.bulkState.done,
                          manager.bulkState.total))
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                ProgressBar(done: manager.bulkState.done,
                            total: manager.bulkState.total)
            }
            if !manager.bulkState.results.isEmpty {
                Text(l.t("bulk.results"))
                    .font(AppTheme.headline(15))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 4)
                ResultsList(results: manager.bulkState.results)
            }
        }
    }
}
