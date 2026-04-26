import SwiftUI

struct BulkActionsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    activeAccountsCard

                    sectionHeader("Подписки и сообщения")
                    NavigationLink(value: BulkScreen.subscribe) {
                        ActionCardRow(icon: "person.crop.circle.badge.plus",
                                      title: l.t("bulk.subscribe"),
                                      subtitle: l.t("bulk.subscribe.placeholder"),
                                      accent: settings.theme.accent)
                    }
                    NavigationLink(value: BulkScreen.leave) {
                        ActionCardRow(icon: "person.crop.circle.badge.minus",
                                      title: "Выйти из канала/чата",
                                      subtitle: "со всех аккаунтов сразу",
                                      accent: AppTheme.danger)
                    }
                    NavigationLink(value: BulkScreen.message) {
                        ActionCardRow(icon: "paperplane.fill",
                                      title: l.t("bulk.message"),
                                      subtitle: l.t("bulk.message.text"),
                                      accent: AppTheme.success)
                    }
                    NavigationLink(value: BulkScreen.autojoin) {
                        ActionCardRow(icon: "list.bullet.rectangle.fill",
                                      title: "Auto-Join по списку",
                                      subtitle: "вставь список ссылок — подпишет на всё",
                                      accent: settings.theme.accent)
                    }

                    sectionHeader("Реакции и опросы")
                    NavigationLink(value: BulkScreen.reactions) {
                        ActionCardRow(icon: "heart.fill",
                                      title: "Bulk Reactions",
                                      subtitle: "поставить эмодзи-реакцию",
                                      accent: AppTheme.danger)
                    }
                    NavigationLink(value: BulkScreen.vote) {
                        ActionCardRow(icon: "checklist",
                                      title: "Bulk Vote",
                                      subtitle: "массовое голосование в опросе",
                                      accent: AppTheme.warning)
                    }
                    NavigationLink(value: BulkScreen.giveaway) {
                        ActionCardRow(icon: "gift.fill",
                                      title: l.t("bulk.giveaway"),
                                      subtitle: l.t("bulk.giveaway.click"),
                                      accent: AppTheme.warning)
                    }
                    NavigationLink(value: BulkScreen.captcha) {
                        ActionCardRow(icon: "checkmark.shield.fill",
                                      title: l.t("bulk.captcha"),
                                      subtitle: l.t("bulk.captcha.start"),
                                      accent: AppTheme.danger)
                    }

                    sectionHeader("Контент")
                    NavigationLink(value: BulkScreen.forward) {
                        ActionCardRow(icon: "arrowshape.turn.up.right.fill",
                                      title: "Bulk Forward",
                                      subtitle: "переслать пост от всех аккаунтов",
                                      accent: settings.theme.accent)
                    }
                    NavigationLink(value: BulkScreen.markRead) {
                        ActionCardRow(icon: "envelope.open.fill",
                                      title: "Mark as Read",
                                      subtitle: "отметить чаты прочитанными",
                                      accent: AppTheme.success)
                    }

                    sectionHeader("Утилиты")
                    NavigationLink(value: BulkScreen.templates) {
                        ActionCardRow(icon: "text.bubble.fill",
                                      title: "Шаблоны",
                                      subtitle: "{first_name}, {username} и др.",
                                      accent: settings.theme.accent)
                    }
                    NavigationLink(value: BulkScreen.scheduler) {
                        ActionCardRow(icon: "calendar.badge.clock",
                                      title: "Расписание",
                                      subtitle: "запланировать bulk на время",
                                      accent: AppTheme.warning)
                    }
                    NavigationLink(value: BulkScreen.about) {
                        ActionCardRow(icon: "questionmark.circle.fill",
                                      title: "Помощь / FAQ",
                                      subtitle: "как всё работает",
                                      accent: AppTheme.success)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.title"))
        .navigationDestination(for: BulkScreen.self) { screen in
            switch screen {
            case .subscribe: BulkSubscribeView()
            case .leave:     BulkLeaveView()
            case .message:   BulkMessageView()
            case .autojoin:  AutoJoinListView()
            case .reactions: BulkReactionsView()
            case .vote:      BulkVoteView()
            case .giveaway:  GiveawayHelperView()
            case .captcha:   CaptchaWizardView()
            case .forward:   BulkForwardView()
            case .markRead:  BulkMarkReadView()
            case .templates: TemplatesView()
            case .scheduler: SchedulerView()
            case .about:     AboutView()
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppTheme.mono(11))
            .foregroundStyle(AppTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private var activeAccountsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(settings.theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(l.t("accounts.count.format",
                          manager.readyAccounts.count,
                          manager.accounts.count))
                    .font(AppTheme.headline(14))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(manager.readyAccounts.map(\.displayLabel).prefix(3).joined(separator: ", "))
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .card(AppTheme.surfaceElevated)
    }
}

enum BulkScreen: Hashable {
    case subscribe, leave, message, autojoin
    case reactions, vote, giveaway, captcha
    case forward, markRead
    case templates, scheduler, about
}
