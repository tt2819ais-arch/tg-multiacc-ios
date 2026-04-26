import SwiftUI

/// Mark a chat's recent messages as read across every account.
struct BulkMarkReadView: View {
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
                    ThemedTextField(title: "Чат",
                                     text: $target,
                                     placeholder: "@chat or t.me/...")
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
                        Text("Прочитать").frame(maxWidth: .infinity)
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
        .navigationTitle("Mark as Read")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let raw = target.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            await manager.runBulk(category: "bulk:read",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                try await acc.markRead(in: raw)
            }
        }
    }
}
