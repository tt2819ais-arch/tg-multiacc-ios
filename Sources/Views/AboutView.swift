import SwiftUI

/// Help / About screen — explains what each tab does, FAQ around
/// FloodWait, sideloading, and a link to the dev's handle.
struct AboutView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    section(title: "Что это", body:
                        "Multi — приложение для управления множеством " +
                        "Telegram-аккаунтов. Все сессии хранятся локально через " +
                        "официальную библиотеку TDLib. Один тап — действие " +
                        "выполняется со всех авторизованных аккаунтов сразу.")

                    section(title: "Как добавить аккаунт", body:
                        "Открой вкладку «Аккаунты» → «Добавить». Введи номер, " +
                        "код из Telegram и (если установлен) облачный 2FA-пароль. " +
                        "Аккаунт сохраняется на устройстве и автоматически " +
                        "восстанавливается при запуске.")

                    section(title: "Bulk-действия", body:
                        "На вкладке «Действия» можно подписаться/выйти, " +
                        "разослать сообщение, поставить реакцию, " +
                        "проголосовать в опросе, переслать пост, " +
                        "пометить чаты прочитанными, или загрузить список " +
                        "ссылок и подписаться на всё разом.")

                    section(title: "Розыгрыши", body:
                        "«Помощник по розыгрышам» получает последнее " +
                        "сообщение чата и позволяет нажать любую inline-кнопку " +
                        "со всех аккаунтов. Капчи проходим по очереди — " +
                        "приложение покажет вопрос с каждого аккаунта.")

                    section(title: "Шаблоны", body:
                        "В шаблонах поддерживаются плейсхолдеры " +
                        "{first_name}, {last_name}, {username}, {phone} — " +
                        "при отправке текст автоматически персонализируется " +
                        "под каждый аккаунт.")

                    section(title: "FloodWait", body:
                        "Если Telegram возвращает FloodWait, приложение " +
                        "ждёт указанное в ошибке количество секунд и " +
                        "повторяет действие. Уменьши частоту в настройках " +
                        "если получаешь много 429.")

                    section(title: "Live Activity", body:
                        "Под чёлкой / на Dynamic Island отображается " +
                        "пилюля с никнеймом разработчика — её можно " +
                        "выключить или сменить текст в настройках.")

                    section(title: "Безопасность", body:
                        "Сессии хранятся в TDLib-базе на устройстве. " +
                        "Включи биометрию в настройках чтобы запрашивать " +
                        "Face ID / Touch ID на вход.")

                    section(title: "Сборка", body:
                        "Приложение собирается на GitHub Actions без подписи. " +
                        "Установить можно через TrollStore, AltStore или " +
                        "Sideloadly.")

                    Link(destination: URL(string: "https://t.me/MaksimXyila")!) {
                        Text("Developer — @MaksimXyila")
                            .font(AppTheme.headline(15))
                            .foregroundStyle(settings.theme.accent)
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
        .navigationTitle("О приложении")
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [settings.theme.accent, AppTheme.success],
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing))
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 88, height: 88)

            Text("Multi").font(AppTheme.mono(13)).foregroundStyle(AppTheme.textTertiary)
            Text("Multi-account Telegram pilot")
                .font(AppTheme.headline(18))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.headline(15))
                .foregroundStyle(AppTheme.textPrimary)
            Text(body)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(AppTheme.surfaceElevated)
    }
}
