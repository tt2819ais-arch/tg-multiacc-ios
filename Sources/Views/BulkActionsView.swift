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
                    NavigationLink(value: BulkScreen.subscribe) {
                        ActionCardRow(icon: "person.crop.circle.badge.plus",
                                      title: l.t("bulk.subscribe"),
                                      subtitle: l.t("bulk.subscribe.placeholder"),
                                      accent: settings.theme.accent)
                    }
                    NavigationLink(value: BulkScreen.message) {
                        ActionCardRow(icon: "paperplane.fill",
                                      title: l.t("bulk.message"),
                                      subtitle: l.t("bulk.message.text"),
                                      accent: AppTheme.success)
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
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.title"))
        .navigationDestination(for: BulkScreen.self) { screen in
            switch screen {
            case .subscribe: BulkSubscribeView()
            case .message:   BulkMessageView()
            case .giveaway:  GiveawayHelperView()
            case .captcha:   CaptchaWizardView()
            }
        }
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

enum BulkScreen: Hashable { case subscribe, message, giveaway, captcha }
