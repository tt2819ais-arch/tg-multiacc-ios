import SwiftUI

/// Bulk leave channel/chat — mirror of `BulkSubscribeView`.
struct BulkLeaveView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @State private var target: String = ""
    @State private var groupTag: String = ""
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ThemedTextField(title: "Канал/чат",
                                     text: $target,
                                     placeholder: "@channel или t.me/...")
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
                        Text("Выйти со всех").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(target.trimmingCharacters(in: .whitespaces).isEmpty
                              || manager.bulkState.isRunning)

                    if !manager.bulkState.results.isEmpty {
                        Text("Результаты")
                            .font(AppTheme.headline(15))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ResultsList(results: manager.bulkState.results)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Bulk Leave")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let raw = target.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            await manager.runBulk(category: "bulk:leave",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                try await acc.leave(from: raw)
            }
        }
    }
}
