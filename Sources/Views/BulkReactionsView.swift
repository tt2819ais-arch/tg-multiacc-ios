import SwiftUI

/// Set an emoji reaction on the latest message of a chat from every account.
struct BulkReactionsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @State private var target: String = ""
    @State private var emoji: String = "❤️"
    @State private var groupTag: String = ""
    @State private var task: Task<Void, Never>?

    private let presetEmojis = ["❤️", "🔥", "👍", "👎", "😁", "😮", "😢", "🎉", "🤩", "💩"]

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ThemedTextField(title: "Чат / канал",
                                     text: $target,
                                     placeholder: "@channel or t.me/...")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Эмодзи реакции")
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                                   spacing: 8) {
                            ForEach(presetEmojis, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e)
                                        .font(.system(size: 28))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(emoji == e ? settings.theme.accent.opacity(0.3) : AppTheme.surface)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(emoji == e ? settings.theme.accent : AppTheme.separator,
                                                              lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ThemedTextField(title: "Или свой эмодзи",
                                         text: $emoji,
                                         placeholder: "🎯",
                                         autocap: .never,
                                         autocorrect: false)
                    }

                    ThemedTextField(title: "Группа аккаунтов (опц.)",
                                     text: $groupTag,
                                     placeholder: "tag")

                    if manager.bulkState.isRunning {
                        ProgressBar(done: manager.bulkState.done,
                                     total: manager.bulkState.total)
                    }
                    Button {
                        run()
                    } label: {
                        Text("Поставить реакцию").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(target.trimmingCharacters(in: .whitespaces).isEmpty
                              || emoji.isEmpty
                              || manager.bulkState.isRunning)

                    if !manager.bulkState.results.isEmpty {
                        ResultsList(results: manager.bulkState.results)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Bulk Reactions")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let raw = target.trimmingCharacters(in: .whitespaces)
        let e = emoji
        guard !raw.isEmpty, !e.isEmpty else { return }
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            await manager.runBulk(category: "bulk:react",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                try await acc.setEmojiReaction(in: raw, emoji: e)
            }
        }
    }
}
