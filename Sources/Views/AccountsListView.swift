import SwiftUI

struct AccountsListView: View {
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var settings: SettingsStore
    @State private var showingAdd = false
    @State private var pendingAccount: TelegramAccount?
    @State private var deleteCandidate: TelegramAccount?

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle(l.t("accounts.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(settings.theme.accent)
                }
            }
        }
        .sheet(item: $pendingAccount, onDismiss: {
            manager.purgePending()
        }) { account in
            AddAccountView(account: account)
                .environmentObject(manager)
                .environmentObject(settings)
        }
        .navigationDestination(for: String.self) { accountId in
            if let acc = manager.accounts.first(where: { $0.id == accountId }) {
                AccountInspectorView(account: acc)
            }
        }
        .alert(l.t("accounts.delete.confirm"), isPresented: Binding(
            get: { deleteCandidate != nil },
            set: { if !$0 { deleteCandidate = nil } }
        )) {
            Button(l.t("common.cancel"), role: .cancel) { deleteCandidate = nil }
            Button(l.t("accounts.delete"), role: .destructive) {
                if let acc = deleteCandidate { manager.remove(acc) }
                deleteCandidate = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if manager.accounts.isEmpty {
            EmptyStateView(
                icon: "person.2.slash",
                title: l.t("accounts.empty"),
                action: (l.t("accounts.add"), startAdd)
            )
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Text(l.t("accounts.count.format",
                                  manager.readyAccounts.count,
                                  manager.accounts.count))
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.top, 4)

                    ForEach(manager.accounts) { account in
                        NavigationLink(value: account.id) {
                            AccountRow(account: account, onDelete: {
                                deleteCandidate = account
                            })
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: startAdd) {
                        Label(l.t("accounts.add"), systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
    }

    private func startAdd() {
        let acc = manager.createPendingAccount()
        pendingAccount = acc
        showingAdd = true
    }
}

private struct AccountRow: View {
    @ObservedObject var account: TelegramAccount
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(account.authState.statusBadge.color.opacity(0.18))
                .overlay(Circle().strokeBorder(account.authState.statusBadge.color, lineWidth: 2))
                .frame(width: 42, height: 42)
                .overlay(
                    Text(initials)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(account.authState.statusBadge.color)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(account.displayLabel)
                    .font(AppTheme.headline(16))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 8) {
                    Text(account.authState.statusBadge.text)
                        .font(AppTheme.mono(11))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4)
                            .fill(account.authState.statusBadge.color.opacity(0.18)))
                        .foregroundStyle(account.authState.statusBadge.color)
                    if !account.meta.phoneNumber.isEmpty {
                        Text(account.meta.phoneNumber)
                            .font(AppTheme.body(13))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundStyle(AppTheme.danger.opacity(0.8))
                    .font(.system(size: 16, weight: .bold))
                    .padding(8)
                    .background(Circle().fill(AppTheme.surfaceElevated))
            }
            .buttonStyle(.plain)
        }
        .card()
    }

    private var initials: String {
        let label = account.displayLabel
        let parts = label.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(label.prefix(2)).uppercased()
    }
}
