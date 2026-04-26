import SwiftUI

/// First-launch coach-marks tour. Shows a 4-step intro overlay above the
/// already-rendered main UI. Each step dims the screen except for a
/// rounded "spotlight" frame and shows a tooltip card explaining the
/// area. The user can advance with the primary button or skip the whole
/// flow at any time.
struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    var onFinish: () -> Void

    @State private var step: Int = 0

    private let steps: [Step] = [
        Step(
            title: "Привет 👋",
            body: "Это TG MULTIACC — приложение для работы со многими Telegram-аккаунтами одновременно. Покажу за минуту, где что лежит.",
            target: .center
        ),
        Step(
            title: "Аккаунты",
            body: "Вкладка «Аккаунты» — здесь ты добавляешь номера, вводишь код и пароль. Каждый аккаунт хранится локально на устройстве.",
            target: .tabAt(index: 1)
        ),
        Step(
            title: "Массовые действия",
            body: "Главная фишка приложения. Подписаться на канал, голосовать в опросе, поставить реакцию, написать одному человеку — всё одной кнопкой со всех аккаунтов.",
            target: .tabAt(index: 2)
        ),
        Step(
            title: "Настройки",
            body: "Темы, язык, размер шрифта, блокировка приложения, Live Activity и много мелочей под себя — всё здесь. Тут же можно отключить эту обводку и любые подсказки.",
            target: .tabAt(index: 4)
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Dim background with a cut-out for the spotlight.
                SpotlightDimMask(rect: spotlightRect(in: proxy.size))
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.selection()
                        next()
                    }

                if let highlight = spotlightRect(in: proxy.size) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.accent, lineWidth: 2)
                        .frame(width: highlight.width, height: highlight.height)
                        .position(x: highlight.midX, y: highlight.midY)
                        .allowsHitTesting(false)
                }

                tooltipCard
                    .frame(maxWidth: 460)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
            }
        }
        .transition(.opacity)
    }

    private var tooltipCard: some View {
        let s = steps[min(step, steps.count - 1)]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx == step ? AppTheme.accent : AppTheme.separator)
                        .frame(width: idx == step ? 22 : 8, height: 4)
                }
                Spacer()
                Button("Пропустить") {
                    Haptics.light()
                    onFinish()
                }
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textTertiary)
            }
            Text(s.title)
                .font(AppTheme.title(22))
                .foregroundStyle(AppTheme.textPrimary)
            Text(s.body)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(step == steps.count - 1 ? "Готово" : "Дальше") {
                Haptics.medium()
                next()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 18, y: 8)
    }

    private func next() {
        if step >= steps.count - 1 {
            onFinish()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
        }
    }

    private func spotlightRect(in size: CGSize) -> CGRect? {
        let s = steps[min(step, steps.count - 1)]
        switch s.target {
        case .center:
            return nil
        case .tabAt(let idx):
            // Approximate iOS tab bar geometry. The bar lives at the very bottom
            // of the screen; tabs are evenly spaced. We highlight one of them.
            let tabBarHeight: CGFloat = 49
            let bottomInset: CGFloat = 34   // homebar safe area on notched iPhones
            let tabsCount: CGFloat = 5
            let tabWidth = size.width / tabsCount
            let x = tabWidth * CGFloat(idx)
            let y = size.height - tabBarHeight - bottomInset
            return CGRect(x: x + 6, y: y - 4, width: tabWidth - 12, height: tabBarHeight + 8)
        }
    }

    private struct Step {
        enum Target {
            case center
            case tabAt(index: Int)
        }
        let title: String
        let body: String
        let target: Target
    }
}

/// Dim layer with a hole punched out around the highlighted rect. Uses
/// `Canvas` so the dim drawing is a single operation — much smoother than
/// stacking shapes with `compositingGroup`.
private struct SpotlightDimMask: View {
    let rect: CGRect?

    var body: some View {
        Canvas { ctx, size in
            let full = Path(CGRect(origin: .zero, size: size))
            ctx.fill(full, with: .color(Color.black.opacity(0.78)))
            if let r = rect {
                let hole = Path(roundedRect: r.insetBy(dx: -4, dy: -4),
                                cornerRadius: 22, style: .continuous)
                ctx.blendMode = .destinationOut
                ctx.fill(hole, with: .color(.black))
            }
        }
        .compositingGroup()
    }
}
