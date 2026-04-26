import SwiftUI
import TDLibKit

/// Resolves a target chat (e.g. a giveaway bot or channel post), fetches its
/// latest message and lists its inline buttons. Tapping a button fires the
/// corresponding callback query on every authorized account.
struct GiveawayHelperView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger

    @State private var target: String = ""
    @State private var fetchedChat: Chat?
    @State private var fetchedMessage: Message?
    @State private var fetchedFromAccount: TelegramAccount?
    @State private var fetching: Bool = false
    @State private var fetchError: String?

    var l: L10n { settings.l10n }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ThemedTextField(title: l.t("bulk.giveaway.target"),
                                    text: $target,
                                    placeholder: l.t("bulk.subscribe.placeholder"))

                    Button(action: { Task { await fetchLatest() } }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text(l.t("bulk.giveaway.fetch"))
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(target.isEmpty || fetching || manager.readyAccounts.isEmpty)

                    if fetching { ProgressView().tint(settings.theme.accent) }

                    if let err = fetchError {
                        Text(err).font(AppTheme.body(13)).foregroundStyle(AppTheme.danger).card()
                    }

                    if let msg = fetchedMessage, let chat = fetchedChat {
                        messageCard(chat: chat, message: msg)
                    }

                    BulkProgressSection()
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.giveaway.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func messageCard(chat: Chat, message: Message) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(settings.theme.accent)
                Text(chat.title).font(AppTheme.headline(15)).foregroundStyle(AppTheme.textPrimary)
            }
            Text(messageText(message))
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(8)

            let buttons = inlineButtons(of: message)
            if buttons.isEmpty {
                Text(l.t("bulk.giveaway.no_buttons"))
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.warning)
            } else {
                Divider().background(AppTheme.separator)
                ForEach(Array(buttons.enumerated()), id: \.offset) { _, btn in
                    Button(action: { Task { await tapButton(btn, on: message) } }) {
                        HStack {
                            Image(systemName: iconFor(btn.type))
                            Text(btn.text).font(AppTheme.headline(14))
                            Spacer()
                            Text(typeLabel(btn.type))
                                .font(AppTheme.mono(11))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!canTap(btn) || manager.bulkState.isRunning)
                }
            }
        }
        .card()
    }

    // MARK: - Logic

    private func fetchLatest() async {
        fetching = true; fetchError = nil
        defer { fetching = false }
        guard let acc = manager.readyAccounts.first else {
            fetchError = l.t("bulk.no_accounts")
            return
        }
        do {
            let (chat, msg) = try await acc.latestMessage(in: target)
            fetchedChat = chat
            fetchedMessage = msg
            fetchedFromAccount = acc
            logger.info("bulk:giveaway", "Latest message fetched from chat \(chat.title) (\(chat.id))")
        } catch {
            fetchError = (error as? TDLibKit.Error).map { "TDLib \($0.code): \($0.message)" }
                ?? error.localizedDescription
            logger.error("bulk:giveaway", "Failed to fetch latest message", error: error)
        }
    }

    private func tapButton(_ btn: InlineKeyboardButton, on message: Message) async {
        guard case .inlineKeyboardButtonTypeCallback(let cb) = btn.type else {
            logger.warning("bulk:giveaway",
                "Unsupported button type \(typeLabel(btn.type)) — skipped")
            return
        }
        let chatId = message.chatId
        let messageId = message.id
        let data = cb.data
        await manager.runBulk(category: "bulk:giveaway",
                               settings: settings) { acc in
            try await acc.clickInlineButton(chatId: chatId,
                                             messageId: messageId,
                                             callbackData: data)
            return "Clicked: \(btn.text)"
        }
    }

    private func canTap(_ btn: InlineKeyboardButton) -> Bool {
        if case .inlineKeyboardButtonTypeCallback = btn.type { return true }
        return false
    }

    private func inlineButtons(of message: Message) -> [InlineKeyboardButton] {
        guard let markup = message.replyMarkup,
              case .replyMarkupInlineKeyboard(let kb) = markup else { return [] }
        return kb.rows.flatMap { $0 }
    }

    private func messageText(_ message: Message) -> String {
        switch message.content {
        case .messageText(let t): return t.text.text
        case .messagePhoto(let p): return p.caption.text.isEmpty ? "<Photo>" : "📷 \(p.caption.text)"
        case .messageVideo(let v): return v.caption.text.isEmpty ? "<Video>" : "🎬 \(v.caption.text)"
        case .messageDocument(let d): return d.caption.text.isEmpty ? "<Document>" : "📄 \(d.caption.text)"
        case .messageAnimation(let a): return a.caption.text.isEmpty ? "<GIF>" : "🎞 \(a.caption.text)"
        case .messageSticker(let s): return "Sticker \(s.sticker.emoji)"
        case .messagePoll(let p): return "📊 \(p.poll.question.text)"
        default: return "<\(String(describing: message.content).prefix(40))>"
        }
    }

    private func typeLabel(_ t: InlineKeyboardButtonType) -> String {
        switch t {
        case .inlineKeyboardButtonTypeUrl: return "URL"
        case .inlineKeyboardButtonTypeLoginUrl: return "Login"
        case .inlineKeyboardButtonTypeWebApp: return "WebApp"
        case .inlineKeyboardButtonTypeCallback: return "Callback"
        case .inlineKeyboardButtonTypeCallbackWithPassword: return "Callback+2FA"
        case .inlineKeyboardButtonTypeCallbackGame: return "Game"
        case .inlineKeyboardButtonTypeSwitchInline: return "Switch"
        case .inlineKeyboardButtonTypeBuy: return "Buy"
        case .inlineKeyboardButtonTypeUser: return "User"
        case .inlineKeyboardButtonTypeCopyText: return "Copy"
        }
    }

    private func iconFor(_ t: InlineKeyboardButtonType) -> String {
        switch t {
        case .inlineKeyboardButtonTypeUrl, .inlineKeyboardButtonTypeLoginUrl, .inlineKeyboardButtonTypeWebApp:
            return "link"
        case .inlineKeyboardButtonTypeCallback, .inlineKeyboardButtonTypeCallbackWithPassword:
            return "hand.tap.fill"
        case .inlineKeyboardButtonTypeCallbackGame: return "gamecontroller.fill"
        case .inlineKeyboardButtonTypeSwitchInline: return "arrow.right.circle"
        case .inlineKeyboardButtonTypeBuy: return "creditcard"
        case .inlineKeyboardButtonTypeUser: return "person.fill"
        case .inlineKeyboardButtonTypeCopyText: return "doc.on.clipboard"
        }
    }
}
