import SwiftUI

struct BulkMessageView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager

    @State private var target: String = ""
    @State private var text: String = ""

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ThemedTextField(title: l.t("bulk.message.target"),
                                    text: $target,
                                    placeholder: l.t("bulk.subscribe.placeholder"))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(l.t("bulk.message.text"))
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        TextEditor(text: $text)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(AppTheme.separator, lineWidth: 1))
                            .foregroundStyle(AppTheme.textPrimary)
                            .font(AppTheme.body(15))
                    }

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
                        HStack { Image(systemName: "paperplane.fill"); Text(l.t("bulk.message.run")) }
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                    disabled: !canRun))
                    .disabled(!canRun)

                    BulkProgressSection()
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.message.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canRun: Bool {
        !target.trimmingCharacters(in: .whitespaces).isEmpty
            && !text.trimmingCharacters(in: .whitespaces).isEmpty
            && !manager.readyAccounts.isEmpty
            && !manager.bulkState.isRunning
    }

    private func run() async {
        let t = target
        let body = text
        await manager.runBulk(category: "bulk:message",
                               settings: settings) { acc in
            let title = try await acc.sendText(to: t, text: body)
            return "Sent → \(title)"
        }
    }
}
