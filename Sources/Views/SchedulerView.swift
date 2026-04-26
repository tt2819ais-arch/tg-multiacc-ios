import SwiftUI

/// View + edit a list of scheduled bulk actions. The actual firing is
/// done by `ScheduleRunner`, which polls every minute while the app is
/// active and runs any actions that are due.
struct SchedulerView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var schedule: ScheduleStore
    @State private var showNew: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            Group {
                if schedule.actions.isEmpty {
                    EmptyStateView(icon: "calendar.badge.clock",
                                    title: "Нет запланированных действий",
                                    action: ("Запланировать", { showNew = true }))
                } else {
                    List {
                        ForEach(schedule.actions) { action in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(action.kind.displayName)
                                        .font(AppTheme.headline(15))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Text(formatted(date: action.fireAt))
                                        .font(AppTheme.mono(12))
                                        .foregroundStyle(settings.theme.accent)
                                }
                                Text(action.target)
                                    .font(AppTheme.body(13))
                                    .foregroundStyle(AppTheme.textSecondary)
                                if let tag = action.groupTag, !tag.isEmpty {
                                    Text("Группа: \(tag)")
                                        .font(AppTheme.body(11))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                            }
                            .listRowBackground(AppTheme.surfaceElevated)
                        }
                        .onDelete { offsets in schedule.remove(at: offsets) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Расписание")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewScheduledActionSheet()
        }
    }

    private func formatted(date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM HH:mm"
        return f.string(from: date)
    }
}

private struct NewScheduledActionSheet: View {
    @EnvironmentObject var schedule: ScheduleStore
    @Environment(\.dismiss) var dismiss

    @State private var kind: ScheduledAction.Kind = .subscribe
    @State private var target: String = ""
    @State private var text: String = ""
    @State private var fireAt: Date = Date().addingTimeInterval(60 * 5)
    @State private var groupTag: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Тип", selection: $kind) {
                    ForEach(ScheduledAction.Kind.allCases) { k in
                        Text(k.displayName).tag(k)
                    }
                }
                Section("Цель") {
                    TextField("@channel или t.me/...", text: $target)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                if kind == .message {
                    Section("Текст") {
                        TextEditor(text: $text)
                            .frame(minHeight: 90)
                    }
                }
                Section("Время") {
                    DatePicker("Запуск", selection: $fireAt, in: Date()...)
                }
                Section("Группа аккаунтов (опц.)") {
                    TextField("tag", text: $groupTag)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Новое расписание")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        let tag = groupTag.trimmingCharacters(in: .whitespaces)
                        let action = ScheduledAction(
                            kind: kind,
                            target: target.trimmingCharacters(in: .whitespaces),
                            text: text,
                            fireAt: fireAt,
                            groupTag: tag.isEmpty ? nil : tag
                        )
                        schedule.add(action)
                        NotificationService.shared.schedule(
                            at: fireAt,
                            title: "Запланированный bulk: \(kind.displayName)",
                            body: action.target,
                            identifier: action.id.uuidString
                        )
                        dismiss()
                    }
                    .disabled(target.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
