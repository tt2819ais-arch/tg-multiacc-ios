import Foundation
import SwiftUI
import TDLibKit

/// Owns the single TDLibClientManager and a list of `TelegramAccount`
/// instances — one per Telegram user. Handles persistence of the account
/// list (each TDLib session is persisted on disk by TDLib itself).
@MainActor
final class AccountManager: ObservableObject {
    private static let metaListKey = "accounts.metaList.v1"

    @Published private(set) var accounts: [TelegramAccount] = []
    @Published var bulkState = BulkState()

    let logger: AppLogger
    private let clientManager: TDLibClientManager

    init(logger: AppLogger = AppLogger.shared) {
        self.logger = logger
        self.clientManager = TDLibClientManager()
        loadStoredAccounts()
    }

    // MARK: - Public API

    var readyAccounts: [TelegramAccount] {
        accounts.filter { $0.authState.isReady }
    }

    func createPendingAccount() -> TelegramAccount {
        let meta = AccountMeta()
        let account = TelegramAccount(meta: meta, manager: self,
                                       clientManager: clientManager,
                                       logger: logger)
        accounts.append(account)
        persistMeta(meta)
        logger.info("manager", "Pending account created: \(meta.id)")
        return account
    }

    func remove(_ account: TelegramAccount) {
        let id = account.id
        Task {
            await account.close()
            await account.logOut()
            await MainActor.run { [weak self] in
                self?.accounts.removeAll { $0.id == id }
                self?.persistAll()
            }
            // Wipe TDLib data on disk for that account.
            let dir = TDConfig.directory(forAccountId: id)
            try? FileManager.default.removeItem(at: dir)
            await MainActor.run { [weak self] in
                self?.logger.info("manager", "Account removed: \(id)")
            }
        }
    }

    /// Drop pending (not-ready) accounts. Used after AddAccount sheet is
    /// dismissed without completing login.
    func purgePending() {
        let pending = accounts.filter {
            !$0.authState.isReady && $0.meta.displayName.isEmpty
        }
        for acc in pending { remove(acc) }
    }

    func persistMeta(_ meta: AccountMeta) {
        // Replace the stored copy.
        if let i = accounts.firstIndex(where: { $0.id == meta.id }) {
            accounts[i].meta = meta
        }
        persistAll()
    }

    /// Logs out + removes every account.
    func logoutAll() {
        let snapshot = accounts
        for acc in snapshot { remove(acc) }
    }

    // MARK: - Persistence

    private func persistAll() {
        let metas = accounts.map { $0.meta }
        if let data = try? JSONEncoder().encode(metas) {
            UserDefaults.standard.set(data, forKey: Self.metaListKey)
        }
    }

    private func loadStoredAccounts() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.metaListKey),
            let metas = try? JSONDecoder().decode([AccountMeta].self, from: data)
        else {
            return
        }
        for meta in metas {
            let acc = TelegramAccount(meta: meta, manager: self,
                                       clientManager: clientManager,
                                       logger: logger)
            accounts.append(acc)
        }
        logger.info("manager", "Loaded \(metas.count) stored account(s)")
    }

}
