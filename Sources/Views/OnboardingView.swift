import SwiftUI

/// First-launch coach-marks tour. Shows a 4-step intro overlay above the
/// already-rendered main UI. The user *must* tap inside the highlighted
/// spotlight to advance — the rest of the screen is dimmed and inert.
/// Step 0 has no spotlight (welcome) so any tap advances. There is a "Skip"
/// button anchored to the top right that finishes the tour at any time.
struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    var onFinish: () -> Void

    @State private var step: Int = 0
    /// Pulse value used to draw an animated ring around the spotlight to make
    /// it obvious where to tap.
    @State private var pulse: Double = 0
    /// Brief flash when the user taps the spotlight, before advancing.
    @State private var flash: Bool = false

    private let steps: [Step] = [
        Step(
            title: "Привет 👋",
            body: "Это Multi — приложение для работы со многими Telegram-аккаунтами одновременно. Тапни в любое место экрана, чтобы продолжить.",
            target: .center
        ),
        Step(
            title: "Аккаунты",
            body: "Тапни на эту вкладку — здесь ты добавляешь номера, вводишь код и пароль. Каждый аккаунт хранится локально.",
            target: .tabAt(index: 1)
        ),
        Step(
            title: "Массовые действия",
            body: "Главная фишка приложения. Подписаться на канал, голосовать, поставить реакцию, написать одному человеку — всё одной кнопкой со всех аккаунтов. Тапни сюда.",
            target: .tabAt(index: 2)
        ),
        Step(
            title: "Настройки",
            body: "Темы, язык, шрифт, блокировка приложения, Live Activity. Всё под себя. Финальный шаг — тапни вкладку «Настройки».",
            target: .tabAt(index: 4)
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            let highlight = spotlightRect(in: proxy.size)

            ZStack {
                // 1. Dim background. Outside the spotlight the dim layer
                //    intercepts taps and gently nudges the user with a haptic
                //    rather than advancing the step. Inside the spotlight the
                //    layer is transparent (cut-out) and lets the user tap.
                SpotlightDimMask(rect: highlight)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Centre step has no spotlight: any tap advances.
                        if highlight == nil {
                            advance()
                        } else {
                            // Wrong area — light haptic to guide attention.
                            Haptics.warning()
                        }
                    }

                // 2. Animated pulsing ring + invisible tap target on the
                //    spotlight itself. This is the only place the user can
                //    tap to advance.
                if let r = highlight {
                    spotlightRing(rect: r)
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: r.width + 16, height: r.height + 16)
                        .position(x: r.midX, y: r.midY)
                        .onTapGesture { advance() }
                }

                // 3. Tooltip card.
                VStack {
                    HStack {
                        Spacer()
                        Button("Пропустить") {
                            Haptics.light()
                            onFinish()
                        }
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.surfaceElevated.opacity(0.85))
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    Spacer()
                    tooltipCard
                        .frame(maxWidth: 460)
                        .padding(.horizontal, 18)
                        .padding(.bottom, tooltipBottomPadding(in: proxy.size))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id(step)
                }

                // 4. Tap-flash so the action feels confirmed.
                if flash {
                    Color.white.opacity(0.18)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
        .transition(.opacity)
    }

    private func spotlightRing(rect r: CGRect) -> some View {
        ZStack {
            // Outer pulsing halo
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.accent.opacity(0.55), lineWidth: 2)
                .frame(width: r.width + CGFloat(pulse) * 18,
                       height: r.height + CGFloat(pulse) * 18)
                .opacity(1.0 - pulse * 0.6)
                .position(x: r.midX, y: r.midY)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                           value: pulse)
                .allowsHitTesting(false)

            // Static inner ring
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.accent, lineWidth: 2.5)
                .frame(width: r.width, height: r.height)
                .position(x: r.midX, y: r.midY)
                .allowsHitTesting(false)
        }
    }

    private var tooltipCard: some View {
        let s = steps[min(step, steps.count - 1)]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx == step ? AppTheme.accent : AppTheme.separator)
                        .frame(width: idx == step ? 22 : 8, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                                   value: step)
                }
                Spacer()
                Text("\(step + 1) / \(steps.count)")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Text(s.title)
                .font(AppTheme.title(22))
                .foregroundStyle(AppTheme.textPrimary)
            Text(s.body)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Hint about what to do next.
            HStack(spacing: 6) {
                Image(systemName: s.target == .center ? "hand.tap.fill" : "hand.point.up.left.fill")
                    .foregroundStyle(AppTheme.accent)
                Text(s.target == .center ? "Тапни в любое место" : "Тапни на подсвеченную область")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.top, 2)
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

    /// Keep the tooltip out of the way of the spotlight: if the spotlight is
    /// near the bottom of the screen (tab bar), float the tooltip higher.
    private func tooltipBottomPadding(in size: CGSize) -> CGFloat {
        guard let r = spotlightRect(in: size) else { return 28 }
        let distanceFromBottom = size.height - r.maxY
        if distanceFromBottom < 140 {
            return 140 + (140 - distanceFromBottom)
        }
        return 28
    }

    private func advance() {
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.18)) { flash = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.18)) { flash = false }
            if step >= steps.count - 1 {
                onFinish()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
            }
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

    fileprivate struct Step: Equatable {
        enum Target: Equatable {
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
