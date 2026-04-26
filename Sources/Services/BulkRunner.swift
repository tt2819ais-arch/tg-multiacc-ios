import Foundation
import SwiftUI
import TDLibKit

struct BulkState: Equatable {
    var category: String = ""
    var isRunning: Bool = false
    var done: Int = 0
    var total: Int = 0
    var results: [BulkActionResult] = []
}

extension BulkActionResult: Equatable {
    static func == (lhs: BulkActionResult, rhs: BulkActionResult) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
extension AccountManager {

    /// Runs `op(account)` over every authorized account, sequentially with
    /// the configured anti-flood delay between accounts. Updates `bulkState`
    /// so the UI can observe progress.
    func runBulk(
        category: String,
        settings: SettingsStore,
        op: @escaping @MainActor (TelegramAccount) async throws -> String
    ) async {
        let snap = readyAccounts
        guard !snap.isEmpty else {
            logger.warning(category, "Bulk skipped: no authorized accounts")
            bulkState = BulkState(category: category, isRunning: false,
                                   done: 0, total: 0, results: [])
            return
        }
        bulkState = BulkState(category: category, isRunning: true,
                               done: 0, total: snap.count, results: [])
        logger.info(category, "Bulk run started for \(snap.count) account(s)")

        let delay = settings.bulkDelaySeconds
        for (i, account) in snap.enumerated() {
            let label = account.displayLabel
            do {
                let detail = try await op(account)
                let r = BulkActionResult(accountId: account.id,
                                          accountLabel: label,
                                          success: true,
                                          detail: detail)
                bulkState.results.append(r)
                logger.success(category, "[\(label)] \(detail)")
            } catch {
                let detail = humanReadable(error)
                let r = BulkActionResult(accountId: account.id,
                                          accountLabel: label,
                                          success: false,
                                          detail: detail)
                bulkState.results.append(r)
                logger.error(category, "[\(label)] \(detail)", error: error)
            }
            bulkState.done = i + 1
            if i < snap.count - 1 && delay > 0 {
                let jitter = Double.random(in: 0.85...1.15)
                let ns = UInt64(delay * jitter * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
            }
        }
        bulkState.isRunning = false
        logger.info(category, "Bulk run finished (\(bulkState.results.filter(\.success).count)/\(bulkState.results.count) ok)")
    }

    fileprivate func humanReadable(_ error: Error) -> String {
        if let tdErr = error as? TDLibKit.Error {
            return "TDLib \(tdErr.code): \(tdErr.message)"
        }
        return error.localizedDescription
    }
}
