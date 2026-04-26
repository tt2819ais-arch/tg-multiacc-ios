import SwiftUI

/// Paste a list of channel/chat links and subscribe to all of them
/// from every account.
struct AutoJoinListView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager

    @State private var bulk: String = ""
    @State private var groupTag: String = ""
    @State private var task: Task<Void, Never>?

    private var entries: [String] {
        bulk.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Список ссылок (по одной на строку)")
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        TextEditor(text: $bulk)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(minHeight: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.surfaceElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppTheme.separator, lineWidth: 1)
                            )
                            .foregroundStyle(AppTheme.textPrimary)
                            .font(AppTheme.mono(13))
                    }
                    Text("Найдено ссылок: \(entries.count)")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                        Text("Запустить").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(entries.isEmpty || manager.bulkState.isRunning)

                    if !manager.bulkState.results.isEmpty {
                        ResultsList(results: manager.bulkState.results)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Auto-Join List")
        .onDisappear { task?.cancel() }
    }

    private func run() {
        let list = entries
        guard !list.isEmpty else { return }
        let tag = groupTag.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : groupTag.trimmingCharacters(in: .whitespaces)
        task?.cancel()
        task = Task {
            // Each account subscribes to every link sequentially. We fold the
            // per-link successes into a single result row to keep the UI
            // readable for huge lists.
            await manager.runBulk(category: "bulk:autojoin",
                                   settings: settings,
                                   tagFilter: tag) { acc in
                var ok = 0
                var fail = 0
                for link in list {
                    do {
                        _ = try await acc.subscribe(to: link)
                        ok += 1
                    } catch {
                        fail += 1
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                return "\(ok) ok, \(fail) failed"
            }
        }
    }
}
