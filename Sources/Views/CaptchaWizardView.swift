import SwiftUI
import TDLibKit

/// Sequential captcha-solving wizard. For each authorized account in turn,
/// fetches the latest message from a target chat (e.g. a giveaway/captcha
/// bot), shows the message + inline buttons + a reply field, and lets the
/// user click a button or send a textual reply on behalf of that account.
struct CaptchaWizardView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger

    @State private var target: String = ""
    @State private var index: Int = 0
    @State private var queue: [TelegramAccount] = []
    @State private var fetchedChat: Chat?
    @State private var fetchedMessage: Message?
    @State private var fetching: Bool = false
    @State private var replyText: String = ""
    @State private var lastError: String?
    @State private var lastInfo: String?
    @State private var started: Bool = false

    var l: L10n { settings.l10n }

    var current: TelegramAccount? {
        guard index >= 0 && index < queue.count else { return nil }
        return queue[index]
    }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !started {
                        ThemedTextField(title: l.t("bulk.captcha.target"),
                                        text: $target,
                                        placeholder: l.t("bulk.subscribe.placeholder"))
                        Button(action: { Task { await start() } }) {
                            HStack { Image(systemName: "play.fill"); Text(l.t("bulk.captcha.start")) }
                        }
                        .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                        disabled: target.isEmpty || manager.readyAccounts.isEmpty))
                        .disabled(target.isEmpty || manager.readyAccounts.isEmpty)
                    } else if let acc = current {
                        accountHeader(acc)
                        if fetching {
                            ProgressView().tint(settings.theme.accent)
                        } else if let msg = fetchedMessage, let chat = fetchedChat {
                            messageCard(chat: chat, message: msg, account: acc)
                            replySection(account: acc)
                        } else if let err = lastError {
                            Text(err).font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.danger).card()
                        }

                        if let info = lastInfo {
                            Text(info).font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.success).card()
                        }

                        HStack {
                            Button(l.t("bulk.captcha.skip")) { Task { await advance() } }
                                .buttonStyle(SecondaryButtonStyle())
                            Button(l.t("bulk.captcha.next")) { Task { await advance() } }
                                .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent))
                        }
                    } else {
                        Text(l.t("bulk.captcha.done")).font(AppTheme.headline(16))
                            .foregroundStyle(AppTheme.success).card()
                        Button(l.t("common.close")) {
                            started = false
                            queue.removeAll()
                            fetchedMessage = nil
                            fetchedChat = nil
                        }.buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(l.t("bulk.captcha.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func accountHeader(_ acc: TelegramAccount) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(settings.theme.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text(acc.displayLabel).font(AppTheme.headline(15)).foregroundStyle(AppTheme.textPrimary)
                Text("\(index + 1) / \(queue.count)")
                    .font(AppTheme.mono(11)).foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
        .card(AppTheme.surfaceElevated)
    }

    @ViewBuilder
    private func messageCard(chat: Chat, message: Message, account: TelegramAccount) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chat.title).font(AppTheme.headline(15)).foregroundStyle(AppTheme.textPrimary)
            Text(messageText(message))
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(10)

            let buttons = inlineButtons(of: message)
            if !buttons.isEmpty {
                Divider().background(AppTheme.separator)
                ForEach(Array(buttons.enumerated()), id: \.offset) { _, btn in
                    Button(action: { Task { await tap(btn, message: message, account: account) } }) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text(btn.text).font(AppTheme.headline(14))
                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!isCallback(btn))
                }
            }
        }
        .card()
    }

    @ViewBuilder
    private func replySection(account: TelegramAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(l.t("bulk.captcha.input"))
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
            TextField("", text: $replyText)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppTheme.separator, lineWidth: 1))
                .foregroundStyle(AppTheme.textPrimary)
                .font(AppTheme.body(15))
            Button(l.t("bulk.captcha.send")) {
                Task { await sendReply(account: account) }
            }
            .buttonStyle(PrimaryButtonStyle(fill: AppTheme.success,
                                            disabled: replyText.isEmpty))
            .disabled(replyText.isEmpty)
        }
    }

    // MARK: - Actions

    private func start() async {
        queue = manager.readyAccounts
        index = 0
        started = true
        await fetchForCurrent()
    }

    private func fetchForCurrent() async {
        lastError = nil
        lastInfo = nil
        replyText = ""
        fetchedChat = nil
        fetchedMessage = nil
        guard let acc = current else { return }
        fetching = true; defer { fetching = false }
        do {
            let (chat, msg) = try await acc.latestMessage(in: target)
            fetchedChat = chat
            fetchedMessage = msg
            logger.info("bulk:captcha", "[\(acc.displayLabel)] fetched latest message")
        } catch {
            lastError = (error as? TDLibKit.Error).map { "TDLib \($0.code): \($0.message)" }
                ?? error.localizedDescription
            logger.error("bulk:captcha", "[\(acc.displayLabel)] fetch failed", error: error)
        }
    }

    private func advance() async {
        index += 1
        if index < queue.count {
            await fetchForCurrent()
        } else {
            fetchedChat = nil
            fetchedMessage = nil
            lastError = nil
            lastInfo = nil
        }
    }

    private func tap(_ btn: InlineKeyboardButton, message: Message, account: TelegramAccount) async {
        guard case .inlineKeyboardButtonTypeCallback(let cb) = btn.type else {
            lastError = "Unsupported button type"
            return
        }
        do {
            try await account.clickInlineButton(chatId: message.chatId,
                                                 messageId: message.id,
                                                 callbackData: cb.data)
            lastInfo = "Clicked: \(btn.text)"
            logger.success("bulk:captcha", "[\(account.displayLabel)] clicked \(btn.text)")
        } catch {
            lastError = (error as? TDLibKit.Error).map { "TDLib \($0.code): \($0.message)" }
                ?? error.localizedDescription
            logger.error("bulk:captcha", "[\(account.displayLabel)] click failed", error: error)
        }
    }

    private func sendReply(account: TelegramAccount) async {
        guard let msg = fetchedMessage else { return }
        do {
            try await account.sendReply(toChatId: msg.chatId,
                                          replyToMessageId: msg.id,
                                          text: replyText)
            lastInfo = "Reply sent"
            replyText = ""
            logger.success("bulk:captcha", "[\(account.displayLabel)] reply sent")
        } catch {
            lastError = (error as? TDLibKit.Error).map { "TDLib \($0.code): \($0.message)" }
                ?? error.localizedDescription
            logger.error("bulk:captcha", "[\(account.displayLabel)] reply failed", error: error)
        }
    }

    // MARK: - Helpers

    private func isCallback(_ btn: InlineKeyboardButton) -> Bool {
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
}
