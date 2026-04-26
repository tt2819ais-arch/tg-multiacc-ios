import Foundation
import TDLibKit

/// One account = one TDLibClient backed by its own database directory on disk.
@MainActor
final class TelegramAccount: ObservableObject, Identifiable {
    let id: String
    @Published var meta: AccountMeta
    @Published var authState: AccountAuthState = .loading
    @Published var lastError: String?
    @Published var lastTdAuthorizationState: String = "loading"

    let client: TDLibClient
    let logger: AppLogger
    weak var managerRef: AccountManager?

    private var pendingPhone: String?

    var displayLabel: String {
        // Prefer the public @username — Telegram lets users set first/last to
        // invisible filler characters (Hangul fillers, ZWSP, lone punctuation),
        // which renders as gibberish in our logs and lists.
        if let u = meta.username, !u.isEmpty { return "@\(u)" }
        let cleaned = Self.sanitizeName(meta.displayName)
        if !cleaned.isEmpty { return cleaned }
        if !meta.phoneNumber.isEmpty { return meta.phoneNumber }
        return "Account #\(id.prefix(6))"
    }

    /// Strip Unicode invisible/whitespace characters that some Telegram
    /// users put in their first / last name fields. Returns an empty string
    /// if the name turns out to be only punctuation/whitespace after the
    /// cleanup, so callers can fall back to @username or phone.
    static func sanitizeName(_ raw: String) -> String {
        let invisibleScalars: Set<Unicode.Scalar> = [
            "\u{200B}", "\u{200C}", "\u{200D}",   // zero-width space / non-joiner / joiner
            "\u{2060}", "\u{FEFF}",                // word joiner / BOM
            "\u{3164}",                            // Hangul filler
            "\u{115F}", "\u{1160}",                // Hangul choseong / jungseong filler
            "\u{17B4}", "\u{17B5}",                // Khmer invisible
            "\u{180E}",                            // Mongolian vowel separator
            "\u{2800}"                             // Braille blank
        ]
        var scalars = String.UnicodeScalarView()
        for scalar in raw.unicodeScalars where !invisibleScalars.contains(scalar) {
            scalars.append(scalar)
        }
        let stripped = String(scalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // If only punctuation is left it's not a meaningful name.
        let meaningful = stripped.unicodeScalars.contains { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }
        return meaningful ? stripped : ""
    }

    init(meta: AccountMeta, manager: AccountManager, clientManager: TDLibClientManager, logger: AppLogger) {
        self.id = meta.id
        self.meta = meta
        self.logger = logger
        self.managerRef = manager

        // Capture id locally so we can route updates without retain cycles.
        let accountId = meta.id
        weak var loggerRef = logger

        // Will fill `account` after construction via `bind`.
        var weakSelfBox: WeakBox<TelegramAccount> = WeakBox(value: nil)

        self.client = clientManager.createClient { data, client in
            // Decode update on the client's update queue.
            do {
                let update = try client.decoder.decode(Update.self, from: data)
                Task { @MainActor in
                    weakSelfBox.value?.handle(update: update)
                }
            } catch {
                // Library version mismatch: TDLib server occasionally adds
                // new fields (`media`, `gift`, etc.) that older Swift
                // bindings don't know about. These misses don't break the
                // app, so we log them at debug level instead of polluting
                // the user-facing error feed.
                loggerRef?.debug("tdlib", "skipped unknown update for \(accountId): \(error.localizedDescription)")
            }
        }

        weakSelfBox.value = self
        bootstrap()
    }

    // MARK: - Bootstrap

    private func bootstrap() {
        let dir = TDConfig.directory(forAccountId: id)
        let dbDir = dir.appendingPathComponent("database").path
        let filesDir = dir.appendingPathComponent("files").path
        Task { @MainActor in
            do {
                _ = try await client.setTdlibParameters(
                    apiHash: TDConfig.apiHash,
                    apiId: TDConfig.apiId,
                    applicationVersion: TDConfig.appVersion,
                    databaseDirectory: dbDir,
                    databaseEncryptionKey: Data(),
                    deviceModel: TDConfig.deviceModel,
                    filesDirectory: filesDir,
                    systemLanguageCode: TDConfig.languageCode,
                    systemVersion: TDConfig.systemVersion,
                    useChatInfoDatabase: true,
                    useFileDatabase: true,
                    useMessageDatabase: true,
                    useSecretChats: false,
                    useTestDc: false
                )
                logger.debug("auth:\(displayLabel)", "setTdlibParameters ok")
            } catch {
                logger.error("auth:\(displayLabel)", "setTdlibParameters failed", error: error)
                authState = .error(String(describing: error))
            }
        }
    }

    // MARK: - Public commands

    func submitPhone(_ phone: String) async {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingPhone = trimmed
        meta.phoneNumber = trimmed
        managerRef?.persistMeta(meta)
        logger.info("auth:\(displayLabel)", "Sending phone number: \(trimmed)")
        do {
            let settings = PhoneNumberAuthenticationSettings(
                allowFlashCall: false,
                allowMissedCall: false,
                allowSmsRetrieverApi: false,
                authenticationTokens: [],
                firebaseAuthenticationSettings: nil,
                hasUnknownPhoneNumber: false,
                isCurrentPhoneNumber: false
            )
            _ = try await client.setAuthenticationPhoneNumber(phoneNumber: trimmed, settings: settings)
        } catch {
            logger.error("auth:\(displayLabel)", "setAuthenticationPhoneNumber failed", error: error)
            authState = .error(humanReadable(error))
        }
    }

    func submitCode(_ code: String) async {
        logger.info("auth:\(displayLabel)", "Submitting login code")
        do {
            _ = try await client.checkAuthenticationCode(code: code.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            logger.error("auth:\(displayLabel)", "checkAuthenticationCode failed", error: error)
            authState = .error(humanReadable(error))
        }
    }

    func submitPassword(_ password: String) async {
        logger.info("auth:\(displayLabel)", "Submitting 2FA password")
        do {
            _ = try await client.checkAuthenticationPassword(password: password)
        } catch {
            logger.error("auth:\(displayLabel)", "checkAuthenticationPassword failed", error: error)
            authState = .error(humanReadable(error))
        }
    }

    func submitRegistration(firstName: String, lastName: String) async {
        do {
            _ = try await client.registerUser(disableNotification: false,
                                               firstName: firstName,
                                               lastName: lastName)
        } catch {
            logger.error("auth:\(displayLabel)", "registerUser failed", error: error)
            authState = .error(humanReadable(error))
        }
    }

    func logOut() async {
        logger.info("auth:\(displayLabel)", "Logging out")
        do {
            _ = try await client.logOut()
        } catch {
            logger.error("auth:\(displayLabel)", "logOut failed", error: error)
        }
    }

    func close() async {
        do { _ = try await client.close() } catch { /* ignore */ }
    }

    // MARK: - Bulk action helpers

    /// Resolves the chat for an arbitrary user input which may be
    /// `@username`, `username`, `https://t.me/username`, `t.me/username`,
    /// `https://t.me/+xxx` (private invite link), or `https://t.me/joinchat/xxx`.
    func resolveChat(_ raw: String) async throws -> Chat {
        let target = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let invite = extractInviteLink(target) {
            do {
                let info = try await client.checkChatInviteLink(inviteLink: invite)
                if info.chatId != 0 {
                    return try await client.getChat(chatId: info.chatId)
                }
            } catch {
                // fall through to join-by-invite below
                logger.debug("resolve", "checkChatInviteLink failed: \(error.localizedDescription)")
            }
            return try await client.joinChatByInviteLink(inviteLink: invite)
        }
        let username = extractUsername(target)
        guard !username.isEmpty else {
            throw NSError(domain: "TGMultiAcc", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot parse target: \(target)"])
        }
        return try await client.searchPublicChat(username: username)
    }

    func subscribe(to raw: String) async throws -> String {
        let chat = try await resolveChat(raw)
        if let invite = extractInviteLink(raw) {
            // Already joined via joinChatByInviteLink inside resolveChat in some cases;
            // joinChat is idempotent if already a member.
            _ = try? await client.joinChatByInviteLink(inviteLink: invite)
        }
        _ = try await client.joinChat(chatId: chat.id)
        return chat.title
    }

    func sendText(to raw: String, text: String) async throws -> String {
        let chat = try await resolveChat(raw)
        let formatted = FormattedText(entities: [], text: text)
        let content = InputMessageContent.inputMessageText(
            InputMessageText(clearDraft: true, linkPreviewOptions: nil, text: formatted)
        )
        _ = try await client.sendMessage(
            chatId: chat.id,
            inputMessageContent: content,
            options: nil,
            replyMarkup: nil,
            replyTo: nil,
            topicId: nil
        )
        return chat.title
    }

    func latestMessage(in raw: String) async throws -> (Chat, Message) {
        let chat = try await resolveChat(raw)
        let history = try await client.getChatHistory(
            chatId: chat.id,
            fromMessageId: 0,
            limit: 1,
            offset: 0,
            onlyLocal: false
        )
        guard let msg = history.messages?.first else {
            throw NSError(domain: "TGMultiAcc", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Chat is empty"])
        }
        return (chat, msg)
    }

    func clickInlineButton(chatId: Int64, messageId: Int64, callbackData: Data) async throws {
        let payload = CallbackQueryPayload.callbackQueryPayloadData(
            CallbackQueryPayloadData(data: callbackData)
        )
        _ = try await client.getCallbackQueryAnswer(
            chatId: chatId,
            messageId: messageId,
            payload: payload
        )
    }

    func sendReply(toChatId chatId: Int64, replyToMessageId: Int64?, text: String) async throws {
        let formatted = FormattedText(entities: [], text: text)
        let content = InputMessageContent.inputMessageText(
            InputMessageText(clearDraft: true, linkPreviewOptions: nil, text: formatted)
        )
        let replyTo: InputMessageReplyTo? = replyToMessageId.map {
            .inputMessageReplyToMessage(
                InputMessageReplyToMessage(checklistTaskId: 0, messageId: $0, pollOptionId: "", quote: nil)
            )
        }
        _ = try await client.sendMessage(
            chatId: chatId,
            inputMessageContent: content,
            options: nil,
            replyMarkup: nil,
            replyTo: replyTo,
            topicId: nil
        )
    }

    // MARK: - Update routing

    private func handle(update: Update) {
        switch update {
        case .updateAuthorizationState(let u):
            handleAuth(u.authorizationState)
        case .updateUser(let u):
            // Fill display name when our own user info arrives.
            if !u.user.firstName.isEmpty || !u.user.lastName.isEmpty {
                let name = [u.user.firstName, u.user.lastName].filter { !$0.isEmpty }.joined(separator: " ")
                if name != meta.displayName {
                    meta.displayName = name
                    if let u = u.user.usernames?.activeUsernames.first {
                        meta.username = u
                    }
                    managerRef?.persistMeta(meta)
                }
            }
        case .updateConnectionState(let u):
            logger.debug("tdlib:\(displayLabel)", "connectionState: \(u.state)")
        default:
            break
        }
    }

    private func handleAuth(_ state: AuthorizationState) {
        let str = String(describing: state).split(separator: "(").first.map(String.init) ?? "?"
        lastTdAuthorizationState = str
        logger.debug("auth:\(displayLabel)", "authorizationState → \(str)")
        switch state {
        case .authorizationStateWaitTdlibParameters:
            authState = .loading
        case .authorizationStateWaitPhoneNumber:
            authState = .waitPhoneNumber
        case .authorizationStateWaitCode(let info):
            let phone = info.codeInfo.phoneNumber
            pendingPhone = phone
            meta.phoneNumber = phone
            managerRef?.persistMeta(meta)
            authState = .waitCode(phoneNumber: phone, info: describeCodeType(info.codeInfo.type))
        case .authorizationStateWaitPassword(let info):
            authState = .waitPassword(hint: info.passwordHint.isEmpty ? nil : info.passwordHint)
        case .authorizationStateWaitRegistration:
            authState = .waitRegistration
        case .authorizationStateReady:
            authState = .ready
            logger.success("auth:\(displayLabel)", "Authorized")
            Task { @MainActor in
                if let user = try? await client.getMe() {
                    let name = [user.firstName, user.lastName].filter { !$0.isEmpty }.joined(separator: " ")
                    if !name.isEmpty { self.meta.displayName = name }
                    if let u = user.usernames?.activeUsernames.first {
                        self.meta.username = u
                    }
                    self.managerRef?.persistMeta(self.meta)
                }
            }
        case .authorizationStateLoggingOut:
            authState = .loggedOut
            logger.warning("auth:\(displayLabel)", "Logging out")
        case .authorizationStateClosed:
            authState = .closed
            logger.warning("auth:\(displayLabel)", "TDLib client closed")
        case .authorizationStateClosing:
            break
        default:
            break
        }
    }

    private func describeCodeType(_ type: AuthenticationCodeType) -> String {
        switch type {
        case .authenticationCodeTypeTelegramMessage:
            return "Telegram message"
        case .authenticationCodeTypeSms:
            return "SMS"
        case .authenticationCodeTypeCall:
            return "Call"
        case .authenticationCodeTypeFlashCall:
            return "Flash call"
        case .authenticationCodeTypeMissedCall:
            return "Missed call"
        case .authenticationCodeTypeFragment:
            return "Fragment"
        case .authenticationCodeTypeFirebaseAndroid, .authenticationCodeTypeFirebaseIos:
            return "Firebase"
        case .authenticationCodeTypeSmsWord, .authenticationCodeTypeSmsPhrase:
            return "SMS"
        }
    }

    // MARK: - Helpers

    private func humanReadable(_ error: Swift.Error) -> String {
        if let err = error as? TDLibKit.Error {
            return "TDLib error \(err.code): \(err.message)"
        }
        return error.localizedDescription
    }

    private func extractUsername(_ raw: String) -> String {
        var s = raw
        if s.hasPrefix("@") { s.removeFirst() }
        if let url = URL(string: s) ?? URL(string: "https://" + s),
           let host = url.host, host.contains("t.me") {
            let parts = url.path.split(separator: "/").map(String.init)
            if let first = parts.first, !first.hasPrefix("+"), first != "joinchat" {
                return first
            }
            if parts.count >= 2 && parts[0] == "joinchat" {
                return ""
            }
            if let first = parts.first, first.hasPrefix("+") {
                return ""
            }
        }
        // strip query / fragments
        if let q = s.firstIndex(of: "?") { s = String(s[..<q]) }
        return s
    }

    private func extractInviteLink(_ raw: String) -> String? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.contains("t.me/+") || s.contains("t.me/joinchat/") {
            if s.lowercased().hasPrefix("http") { return s }
            return "https://" + s.replacingOccurrences(of: "https://", with: "")
                                 .replacingOccurrences(of: "http://", with: "")
        }
        return nil
    }
}

private final class WeakBox<T: AnyObject> {
    weak var value: T?
    init(value: T?) { self.value = value }
}
