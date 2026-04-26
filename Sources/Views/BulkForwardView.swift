import SwiftUI

/// Forward the latest message from one chat to another, from every account.
struct BulkForwardView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @State private var source: String = ""
    @State private var destination: String = ""
    @State private var groupTag: String = ""
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ThemedTextField(title: "Источник",
                                     text: $source,
                                     placeholder: "@source or t.me/...")
                    ThemedTextField(title: "Куда переслать",
                                     text: $destination,
                                     placeholder: "@destination or t.me/...")
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
                        Text("Переслать").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(source.trimmingCharacters(in: .whitespaces).isEmpty
                              || destination.trimmingCharacters(in: .whitespaces).isEmpty
                              || manager.bulkState.isRunning)

                    if !manager.bulkState.results.isEmpty {
                        ResultsList(results: manager.bulkState.results)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Bulk Forward")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let s = source.trimmingCharacters(in: .whitespaces)
        let d = destination.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !d.isEmpty else { return }
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            await manager.runBulk(category: "bulk:forward",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                try await acc.forwardLatest(from: s, to: d)
            }
        }
    }
}
