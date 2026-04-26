import Foundation
import TDLibKit

/// Additional bulk-action helpers built on top of `TelegramAccount`. These
/// are kept in a separate file to keep the core class focused and to make
/// it easy to grow the feature surface without touching the auth flow.
@MainActor
extension TelegramAccount {

    // MARK: - Leave / forward / mark-read / forward

    func leave(from raw: String) async throws -> String {
        let chat = try await resolveChat(raw)
        _ = try await client.leaveChat(chatId: chat.id)
        return chat.title
    }

    func forwardLatest(from raw: String, to destinationRaw: String) async throws -> String {
        let (sourceChat, latest) = try await latestMessage(in: raw)
        let dest = try await resolveChat(destinationRaw)
        _ = try await client.forwardMessages(
            chatId: dest.id,
            fromChatId: sourceChat.id,
            messageIds: [latest.id],
            options: nil,
            removeCaption: false,
            sendCopy: false,
            topicId: nil
        )
        return "→ \(dest.title)"
    }

    func markRead(in raw: String) async throws -> String {
        let chat = try await resolveChat(raw)
        let history = try await client.getChatHistory(
            chatId: chat.id,
            fromMessageId: 0,
            limit: 30,
            offset: 0,
            onlyLocal: false
        )
        let ids = (history.messages ?? []).map { $0.id }
        if !ids.isEmpty {
            _ = try await client.viewMessages(
                chatId: chat.id,
                forceRead: true,
                messageIds: ids,
                source: .messageSourceChatHistory
            )
        }
        return chat.title
    }

    func setEmojiReaction(in raw: String, emoji: String) async throws -> String {
        let (chat, msg) = try await latestMessage(in: raw)
        _ = try await client.addMessageReaction(
            chatId: chat.id,
            isBig: false,
            messageId: msg.id,
            reactionType: .reactionTypeEmoji(ReactionTypeEmoji(emoji: emoji)),
            updateRecentReactions: true
        )
        return chat.title
    }

    func voteInLatestPoll(in raw: String, optionIndex: Int) async throws -> String {
        let (chat, msg) = try await latestMessage(in: raw)
        guard case .messagePoll = msg.content else {
            throw NSError(
                domain: "TGMultiAcc", code: 10,
                userInfo: [NSLocalizedDescriptionKey: "Latest message is not a poll"]
            )
        }
        _ = try await client.setPollAnswer(
            chatId: chat.id,
            messageId: msg.id,
            optionIds: [optionIndex]
        )
        return "voted opt #\(optionIndex) in \(chat.title)"
    }

    // MARK: - Proxy

    func applyProxy(_ proxy: ProxyConfig?) async throws {
        if let proxy {
            let type: ProxyType
            switch proxy.kind {
            case .socks5:
                type = .proxyTypeSocks5(ProxyTypeSocks5(password: proxy.password,
                                                        username: proxy.username))
            case .http:
                type = .proxyTypeHttp(ProxyTypeHttp(httpOnly: false,
                                                    password: proxy.password,
                                                    username: proxy.username))
            case .mtproto:
                type = .proxyTypeMtproto(ProxyTypeMtproto(secret: proxy.secret))
            }
            _ = try await client.addProxy(
                enable: true,
                proxy: Proxy(port: proxy.port, server: proxy.host, type: type)
            )
        } else {
            _ = try await client.disableProxy()
        }
    }

    // MARK: - Chats / profile

    func loadChatsList(limit: Int = 100) async throws -> [Chat] {
        _ = try? await client.loadChats(chatList: nil, limit: limit)
        let chats = try await client.getChats(chatList: nil, limit: limit)
        var result: [Chat] = []
        for id in (chats.chatIds ?? []) {
            if let chat = try? await client.getChat(chatId: id) {
                result.append(chat)
            }
        }
        return result
    }

    func searchChatsList(query: String, limit: Int = 50) async throws -> [Chat] {
        let chats = try await client.searchChats(limit: limit, query: query)
        var result: [Chat] = []
        for id in (chats.chatIds ?? []) {
            if let chat = try? await client.getChat(chatId: id) {
                result.append(chat)
            }
        }
        return result
    }

    func fetchSelfUser() async -> User? {
        try? await client.getMe()
    }
}
