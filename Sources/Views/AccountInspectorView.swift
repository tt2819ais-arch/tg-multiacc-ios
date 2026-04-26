import SwiftUI
import TDLibKit

/// Drill-down on a single Telegram account: profile, tags, proxy, latest
/// chats, sign-out. Lets the user edit metadata (display label, tags,
/// note) and configure a proxy that will be applied next session.
struct AccountInspectorView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @ObservedObject var account: TelegramAccount

    @State private var note: String = ""
    @State private var tags: String = ""
    @State private var loadingChats: Bool = false
    @State private var chats: [Chat] = []
    @State private var showProxy: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    profileCard
                    metaCard
                    proxyCard
                    chatsCard
                    dangerCard
                }
                .padding(16)
            }
        }
        .navigationTitle(account.displayLabel)
        .onAppear {
            note = account.meta.note
            tags = account.meta.tags.joined(separator: ", ")
            Task { await refreshChats() }
        }
        .sheet(isPresented: $showProxy) {
            ProxyEditorSheet(account: account)
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(settings.theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayLabel)
                        .font(AppTheme.headline(18))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(account.meta.phoneNumber.isEmpty ? "—" : account.meta.phoneNumber)
                        .font(AppTheme.mono(13))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                let badge = account.authState.statusBadge
                Text(badge.text.uppercased())
                    .font(AppTheme.mono(11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badge.color.opacity(0.18))
                    .foregroundStyle(badge.color)
                    .clipShape(Capsule())
            }
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Metadata

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Метаданные").font(AppTheme.headline(15))
                .foregroundStyle(AppTheme.textPrimary)
            ThemedTextField(title: "Теги (через запятую)",
                             text: $tags,
                             placeholder: "work, giveaways")
            ThemedTextField(title: "Заметка",
                             text: $note,
                             placeholder: "")
            Button("Сохранить") {
                var meta = account.meta
                meta.note = note.trimmingCharacters(in: .whitespaces)
                meta.tags = tags.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                manager.persistMeta(meta)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Proxy

    private var proxyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Прокси").font(AppTheme.headline(15))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button { showProxy = true } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(settings.theme.accent)
                }
            }
            if let p = account.meta.proxy {
                Text("\(p.kind.displayName) \(p.host):\(p.port)")
                    .font(AppTheme.mono(13))
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                Text("Не задан").font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Chats

    private var chatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Чаты (топ 50)").font(AppTheme.headline(15))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    Task { await refreshChats() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(settings.theme.accent)
                }
            }
            if loadingChats {
                ProgressView().tint(settings.theme.accent)
            } else if chats.isEmpty {
                Text("Список пуст. Нажми обновить.")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                ForEach(chats.prefix(50), id: \.id) { chat in
                    HStack(spacing: 10) {
                        Image(systemName: chatIcon(chat))
                            .frame(width: 20)
                            .foregroundStyle(settings.theme.accent)
                        Text(chat.title.isEmpty ? "(без названия)" : chat.title)
                            .font(AppTheme.body(14))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if chat.unreadCount > 0 {
                            Text("\(chat.unreadCount)")
                                .font(AppTheme.mono(11))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(settings.theme.accent.opacity(0.25))
                                .foregroundStyle(settings.theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .card(AppTheme.surfaceElevated)
    }

    private func chatIcon(_ chat: Chat) -> String {
        switch chat.type {
        case .chatTypePrivate: return "person.fill"
        case .chatTypeBasicGroup: return "person.3.fill"
        case .chatTypeSupergroup(let s): return s.isChannel ? "megaphone.fill" : "bubble.left.and.bubble.right.fill"
        case .chatTypeSecret: return "lock.fill"
        }
    }

    // MARK: - Danger

    private var dangerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Опасная зона").font(AppTheme.headline(15))
                .foregroundStyle(AppTheme.danger)
            Button("Удалить аккаунт") {
                manager.remove(account)
            }
            .buttonStyle(DangerButtonStyle())
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Helpers

    @MainActor
    private func refreshChats() async {
        loadingChats = true
        defer { loadingChats = false }
        if let result = try? await account.loadChatsList(limit: 50) {
            chats = result
        }
    }
}

private struct ProxyEditorSheet: View {
    @ObservedObject var account: TelegramAccount
    @EnvironmentObject var manager: AccountManager
    @Environment(\.dismiss) var dismiss

    @State private var enabled: Bool = false
    @State private var kind: ProxyConfig.Kind = .socks5
    @State private var host: String = ""
    @State private var port: Int = 1080
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var secret: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Использовать прокси", isOn: $enabled)
                if enabled {
                    Picker("Тип", selection: $kind) {
                        ForEach(ProxyConfig.Kind.allCases) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    Section("Сервер") {
                        TextField("host", text: $host)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.URL)
                        Stepper(value: $port, in: 1...65535) {
                            Text("Порт: \(port)")
                        }
                    }
                    if kind != .mtproto {
                        Section("Аутентификация") {
                            TextField("login", text: $username)
                                .textInputAutocapitalization(.never)
                            SecureField("password", text: $password)
                        }
                    }
                    if kind == .mtproto {
                        Section("MTProto secret") {
                            TextField("hex-секрет", text: $secret)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                        }
                    }
                }
            }
            .navigationTitle("Прокси")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(enabled && host.isEmpty)
                }
            }
            .onAppear {
                if let p = account.meta.proxy {
                    enabled = true
                    kind = p.kind
                    host = p.host
                    port = p.port
                    username = p.username
                    password = p.password
                    secret = p.secret
                }
            }
        }
    }

    private func save() {
        var meta = account.meta
        if enabled {
            meta.proxy = ProxyConfig(
                kind: kind,
                host: host.trimmingCharacters(in: .whitespaces),
                port: port,
                username: username,
                password: password,
                secret: secret.trimmingCharacters(in: .whitespaces)
            )
        } else {
            meta.proxy = nil
        }
        manager.persistMeta(meta)
        let proxy = meta.proxy
        Task { try? await account.applyProxy(proxy) }
        dismiss()
    }
}
