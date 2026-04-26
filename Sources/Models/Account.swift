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
    var tags: [String]
    var note: String
    var proxy: ProxyConfig?

    init(id: String = UUID().uuidString,
         phoneNumber: String = "",
         displayName: String = "",
         username: String? = nil,
         addedAt: Date = Date(),
         tags: [String] = [],
         note: String = "",
         proxy: ProxyConfig? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.username = username
        self.addedAt = addedAt
        self.tags = tags
        self.note = note
        self.proxy = proxy
    }
}

/// Optional proxy configuration that can be applied per account.
struct ProxyConfig: Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case socks5
        case mtproto
        case http
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .socks5: return "SOCKS5"
            case .mtproto: return "MTProto"
            case .http: return "HTTP"
            }
        }
    }

    var kind: Kind
    var host: String
    var port: Int
    var username: String       // SOCKS5 username, empty if none
    var password: String       // SOCKS5/HTTP password, empty if none
    var secret: String         // MTProto hex secret, empty otherwise

    init(kind: Kind = .socks5,
         host: String = "",
         port: Int = 1080,
         username: String = "",
         password: String = "",
         secret: String = "") {
        self.kind = kind
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.secret = secret
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

    var shortDescription: String {
        switch self {
        case .loading: return "loading"
        case .waitPhoneNumber: return "waitPhoneNumber"
        case .waitCode: return "waitCode"
        case .waitPassword: return "waitPassword"
        case .waitRegistration: return "waitRegistration"
        case .ready: return "ready"
        case .loggedOut: return "loggedOut"
        case .closed: return "closed"
        case .error(let m): return "error(\(m.prefix(40)))"
        }
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

/// A user-editable message template. Supports placeholders
/// `{first_name}` / `{last_name}` / `{username}` / `{phone}` for personalized
/// outgoing messages from each account's perspective.
struct MessageTemplate: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String = "",
         body: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
    }

    func render(for meta: AccountMeta) -> String {
        let firstName: String
        let lastName: String
        let split = meta.displayName.split(separator: " ", maxSplits: 1).map(String.init)
        if split.count == 2 {
            firstName = split[0]
            lastName = split[1]
        } else {
            firstName = split.first ?? ""
            lastName = ""
        }
        return body
            .replacingOccurrences(of: "{first_name}", with: firstName)
            .replacingOccurrences(of: "{last_name}", with: lastName)
            .replacingOccurrences(of: "{username}", with: meta.username ?? "")
            .replacingOccurrences(of: "{phone}", with: meta.phoneNumber)
    }
}

/// Stored configuration for a scheduled bulk action.
struct ScheduledAction: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case subscribe
        case message
        case leave
        case markRead
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .subscribe: return "Subscribe"
            case .message:   return "Message"
            case .leave:     return "Leave"
            case .markRead:  return "Mark as read"
            }
        }
    }

    var id: UUID
    var kind: Kind
    var target: String        // chat link / username
    var text: String          // payload (for message)
    var fireAt: Date
    var groupTag: String?     // optional tag filter
    var createdAt: Date

    init(id: UUID = UUID(),
         kind: Kind,
         target: String,
         text: String = "",
         fireAt: Date,
         groupTag: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.target = target
        self.text = text
        self.fireAt = fireAt
        self.groupTag = groupTag
        self.createdAt = createdAt
    }
}
