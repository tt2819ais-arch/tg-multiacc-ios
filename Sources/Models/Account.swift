import Foundation

/// Persisted, lightweight metadata about each Telegram account stored in
/// UserDefaults. The full session lives inside the account's TDLib database
/// directory on disk; this struct only holds the bookkeeping needed to
/// re-create a `TelegramAccount` on next launch.
struct AccountMeta: Codable, Identifiable, Hashable {
    let id: String                  // stable UUID, used as folder name
    var phoneNumber: String         // last known phone (for display)
    var displayName: String         // "First Last" or @username
    var username: String?
    var addedAt: Date

    init(id: String = UUID().uuidString,
         phoneNumber: String = "",
         displayName: String = "",
         username: String? = nil,
         addedAt: Date = Date()) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.username = username
        self.addedAt = addedAt
    }
}

enum AccountAuthState: Equatable {
    case loading
    case waitPhoneNumber
    case waitCode(phoneNumber: String, info: String?)
    case waitPassword(hint: String?)
    case waitRegistration
    case ready
    case loggedOut
    case error(String)
    case closed

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// Result of running a single bulk action against one account.
struct BulkActionResult: Identifiable {
    let id = UUID()
    let accountId: String
    let accountLabel: String
    let success: Bool
    let detail: String
    let date: Date = Date()
}
