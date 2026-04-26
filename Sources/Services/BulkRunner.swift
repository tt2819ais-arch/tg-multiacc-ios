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
    /// - Parameters:
    ///   - tagFilter: optional tag — only accounts whose `meta.tags` contain
    ///                this string (case-insensitive) will be used.
    ///   - op: the per-account async operation that returns a short detail
    ///         string for the result row.
    func runBulk(
        category: String,
        settings: SettingsStore,
        tagFilter: String? = nil,
        op: @escaping @MainActor (TelegramAccount) async throws -> String
    ) async {
        var snap = readyAccounts
        if let tag = tagFilter, !tag.isEmpty {
            snap = snap.filter { acc in
                acc.meta.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
            }
        }
        guard !snap.isEmpty else {
            logger.warning(category, "Bulk skipped: no matching authorized accounts")
            bulkState = BulkState(category: category, isRunning: false,
                                   done: 0, total: 0, results: [])
            return
        }
        bulkState = BulkState(category: category, isRunning: true,
                               done: 0, total: snap.count, results: [])
        logger.info(category, "Bulk run started for \(snap.count) account(s)")

        let delay = settings.bulkDelaySeconds
        let smart = settings.smartRetryOnFlood
        let maxRetries = settings.maxFloodRetries

        for (i, account) in snap.enumerated() {
            let label = account.displayLabel
            var attempt = 0
            var finalResult: BulkActionResult?
            while finalResult == nil {
                do {
                    let detail = try await op(account)
                    finalResult = BulkActionResult(accountId: account.id,
                                                    accountLabel: label,
                                                    success: true,
                                                    detail: detail)
                    logger.success(category, "[\(label)] \(detail)")
                } catch let tdErr as TDLibKit.Error where smart && attempt < maxRetries
                    && tdErr.message.uppercased().contains("FLOOD") {
                    let waitSec = parseFloodWait(tdErr.message) ?? settings.floodFallbackSeconds
                    attempt += 1
                    logger.warning(category,
                                    "[\(label)] FloodWait \(waitSec)s, retry \(attempt)/\(maxRetries)")
                    try? await Task.sleep(nanoseconds: UInt64(waitSec * 1_000_000_000))
                } catch {
                    let detail = humanReadable(error)
                    finalResult = BulkActionResult(accountId: account.id,
                                                    accountLabel: label,
                                                    success: false,
                                                    detail: detail)
                    logger.error(category, "[\(label)] \(detail)", error: error)
                }
            }
            if let r = finalResult { bulkState.results.append(r) }
            bulkState.done = i + 1
            if i < snap.count - 1 && delay > 0 {
                let jitter = Double.random(in: 0.85...1.15)
                let ns = UInt64(delay * jitter * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
            }
        }
        bulkState.isRunning = false
        let ok = bulkState.results.filter(\.success).count
        let total = bulkState.results.count
        logger.info(category, "Bulk run finished (\(ok)/\(total) ok)")
        if settings.notifyOnBulkCompletion {
            NotificationService.shared.notifyNow(
                title: "Bulk \"\(category)\" finished",
                body: "\(ok)/\(total) succeeded"
            )
        }
    }

    private func parseFloodWait(_ message: String) -> Int? {
        // TDLib returns messages like "Too Many Requests: retry after 17"
        let parts = message.split(whereSeparator: { !$0.isNumber })
        for p in parts.reversed() {
            if let n = Int(p) { return n }
        }
        return nil
    }

    fileprivate func humanReadable(_ error: Swift.Error) -> String {
        if let tdErr = error as? TDLibKit.Error {
            return "TDLib \(tdErr.code): \(tdErr.message)"
        }
        return error.localizedDescription
    }
}
