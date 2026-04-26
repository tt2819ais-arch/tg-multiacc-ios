import SwiftUI

/// Vote in the latest poll of a chat from every account.
struct BulkVoteView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @State private var target: String = ""
    @State private var optionIndex: Int = 0
    @State private var groupTag: String = ""
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ThemedTextField(title: "Чат с опросом",
                                     text: $target,
                                     placeholder: "@channel or t.me/...")
                    Stepper(value: $optionIndex, in: 0...20) {
                        Text("Вариант ответа: #\(optionIndex)")
                            .foregroundStyle(AppTheme.textPrimary)
                            .font(AppTheme.body(15))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.surfaceElevated)
                    )
                    ThemedTextField(title: "Группа (опц.)",
                                     text: $groupTag,
                                     placeholder: "tag")
                    if manager.bulkState.isRunning {
                        ProgressBar(done: manager.bulkState.done,
                                     total: manager.bulkState.total)
                    }
                    Button {
                        run()
                    } label: {
                        Text("Проголосовать").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(target.trimmingCharacters(in: .whitespaces).isEmpty
                              || manager.bulkState.isRunning)

                    if !manager.bulkState.results.isEmpty {
                        ResultsList(results: manager.bulkState.results)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Bulk Vote")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let raw = target.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let opt = optionIndex
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            await manager.runBulk(category: "bulk:vote",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                try await acc.voteInLatestPoll(in: raw, optionIndex: opt)
            }
        }
    }
}
