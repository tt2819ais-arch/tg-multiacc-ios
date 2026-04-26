import SwiftUI

/// Manage reusable message templates with `{first_name}` / `{last_name}` /
/// `{username}` / `{phone}` placeholders.
struct TemplatesView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var templates: TemplatesStore
    @State private var editing: MessageTemplate?
    @State private var showNew: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            Group {
                if templates.templates.isEmpty {
                    EmptyStateView(icon: "text.bubble.fill",
                                    title: "Шаблонов пока нет.\nСоздай первый для рассылок.",
                                    action: ("Создать шаблон", { showNew = true }))
                } else {
                    List {
                        ForEach(templates.templates) { tpl in
                            Button {
                                editing = tpl
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tpl.title.isEmpty ? "(без названия)" : tpl.title)
                                        .font(AppTheme.headline(15))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(tpl.body)
                                        .font(AppTheme.body(13))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(3)
                                }
                            }
                            .listRowBackground(AppTheme.surfaceElevated)
                        }
                        .onDelete { offsets in templates.delete(at: offsets) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Шаблоны")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            TemplateEditorSheet(template: MessageTemplate())
        }
        .sheet(item: $editing) { tpl in
            TemplateEditorSheet(template: tpl)
        }
    }
}

private struct TemplateEditorSheet: View {
    @EnvironmentObject var templates: TemplatesStore
    @Environment(\.dismiss) var dismiss

    @State var template: MessageTemplate

    private let isNew: Bool

    init(template: MessageTemplate) {
        self._template = State(initialValue: template)
        self.isNew = templates_isEmpty(template)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ThemedTextField(title: "Название",
                                     text: $template.title,
                                     placeholder: "Welcome msg",
                                     autocap: .sentences,
                                     autocorrect: true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Текст".uppercased())
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                        TextEditor(text: $template.body)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.surfaceElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppTheme.separator, lineWidth: 1)
                            )
                            .font(AppTheme.body(15))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Text("Доступные плейсхолдеры: {first_name}, {last_name}, {username}, {phone}")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        save()
                    } label: {
                        Text("Сохранить").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(template.body.isEmpty)
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "Новый шаблон" : "Редактирование")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private func save() {
        if isNew {
            templates.add(template)
        } else {
            templates.update(template)
        }
        dismiss()
    }
}

private func templates_isEmpty(_ t: MessageTemplate) -> Bool {
    t.title.isEmpty && t.body.isEmpty
}
