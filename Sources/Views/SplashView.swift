import SwiftUI

/// Minimalist boot screen. Shows a single rotating quote in the top-left
/// corner over the current theme background. No flashy effects — picked
/// after the user explicitly asked for a calmer look.
struct SplashView: View {
    @EnvironmentObject var settings: SettingsStore
    var onFinish: () -> Void

    @State private var quote: String = SplashQuotes.random()
    @State private var visible: Bool = false
    @State private var fade: Double = 1.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            settings.theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                Text("Developer — @MaksimXyila")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)
                    .opacity(visible ? 1 : 0)

                Text(quote)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(visible ? 1 : 0)
            }
            .padding(.top, 60)
            .padding(.leading, 22)
            .padding(.trailing, 32)

            // Hidden full-screen tap target so the user can skip if they want.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { finish() }
        }
        .opacity(fade)
        .onAppear { run() }
    }

    private func run() {
        withAnimation(.easeOut(duration: 0.45)) { visible = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await finishAnimated()
        }
    }

    private func finishAnimated() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.35)) { fade = 0.0 }
        }
        try? await Task.sleep(nanoseconds: 380_000_000)
        await MainActor.run { onFinish() }
    }

    private func finish() {
        Task { await finishAnimated() }
    }
}

/// Curated list of one-liners shown in the corner of the splash screen.
/// Picked at random per launch — no neon, no shouting, just lightly-witty
/// flavor copy supplied by the user.
enum SplashQuotes {
    static let all: [String] = [
        "Похоже, у тебя аккаунтов больше, чем носков 😄",
        "Переключился… и на секунду завис, кто ты",
        "Один аккаунт? Это было давно",
        "«Я с другого аккаунта» — звучит знакомо",
        "Иногда ты сам себе подписчик 😉",
        "Кто ты сегодня?",
        "Кажется, этот чат был не отсюда…",
        "С третьего аккаунта начинается магия 😅",
        "Пишешь и надеешься, что туда",
        "Запомнить все логины — тот ещё квест",
        "Главное — выглядеть уверенно",
        "Это личка или работа?",
        "Переключение уже на автомате",
        "Кажется, ты это уже отправлял",
        "Ошибся аккаунтом? Ничего страшного",
        "Иногда ты ведёшь диалог сам с собой",
        "Главное — не палиться 😎",
        "Это был план… наверное",
        "Немного разных «я» — это нормально",
        "Чат знакомый… а аккаунт?",
        "Ты уже был тут, просто другим",
        "Уведомлений всегда чуть больше, чем ждёшь",
        "Один ты — много ролей",
        "Почти всегда попадаешь в нужный чат",
        "Иногда лайкаешь сам себя — и это ок",
        "«Это не я писал» — почти правда",
        "Всё под контролем… почти",
        "Чем больше аккаунтов, тем интереснее",
        "Ты переключаешься быстрее, чем думаешь",
        "Добро пожаловать в мульти-версию себя ✨"
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}
