import SwiftUI

/// Boot screen with animated particle field and a typewriter signature.
struct SplashView: View {
    @EnvironmentObject var settings: SettingsStore
    var onFinish: () -> Void

    @State private var typedTitle: String = ""
    @State private var typedSub: String = ""
    @State private var showCursor: Bool = true
    @State private var fade: Double = 1.0

    private let titleFull = "TG MULTIACC"
    private let subFull = "Developer — @MaksimXyila"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ParticleField()
                .ignoresSafeArea()
                .blendMode(.plusLighter)
                .opacity(0.85)

            VStack(spacing: 18) {
                Spacer()
                Text(typedTitle)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(LinearGradient(
                        colors: [.white, AppTheme.accent.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing))
                    .shadow(color: AppTheme.accent.opacity(0.6), radius: 12)

                HStack(spacing: 0) {
                    Text(typedSub)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(showCursor ? "▌" : " ")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                Text("tap anywhere to skip")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .opacity(fade)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { run() }
    }

    private func run() {
        Task {
            // Cursor blink loop
            withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                showCursor.toggle()
            }
            // Type the title
            for ch in titleFull {
                await MainActor.run { typedTitle.append(ch) }
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            // Type the sub-line
            for ch in subFull {
                await MainActor.run { typedSub.append(ch) }
                try? await Task.sleep(nanoseconds: 45_000_000)
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await finishAnimated()
        }
    }

    private func finishAnimated() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.45)) { fade = 0.0 }
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run { onFinish() }
    }

    private func finish() {
        Task { await finishAnimated() }
    }
}

private struct ParticleField: View {
    @State private var particles: [Particle] = (0..<70).map { _ in Particle.random() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let t = now * p.speed + p.phase
                    let x = (sin(t * 0.5) * 0.5 + 0.5) * size.width * p.xSpan + p.xOffset * size.width
                    let y = (cos(t * 0.6) * 0.5 + 0.5) * size.height * p.ySpan + p.yOffset * size.height
                    let r = p.radius
                    let circle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    let alpha = 0.15 + 0.55 * (sin(t * p.flicker) * 0.5 + 0.5)
                    ctx.fill(circle, with: .color(p.color.opacity(alpha)))
                    // soft glow
                    let g = Path(ellipseIn: CGRect(x: x - r * 5, y: y - r * 5, width: r * 10, height: r * 10))
                    ctx.fill(g, with: .color(p.color.opacity(alpha * 0.06)))
                }

                // subtle grid lines
                let gridColor = Color.white.opacity(0.03)
                let step: CGFloat = 38
                var path = Path()
                var x: CGFloat = 0
                while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                var y: CGFloat = 0
                while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                ctx.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
        }
    }

    struct Particle {
        let radius: CGFloat
        let speed: Double
        let phase: Double
        let xSpan: Double
        let ySpan: Double
        let xOffset: Double
        let yOffset: Double
        let flicker: Double
        let color: Color

        static func random() -> Particle {
            let palette: [Color] = [
                Color(red: 0.20, green: 0.60, blue: 1.00),
                Color(red: 0.40, green: 0.90, blue: 1.00),
                Color(red: 0.85, green: 0.40, blue: 1.00),
                Color.white
            ]
            return Particle(
                radius: CGFloat.random(in: 0.8...2.6),
                speed: Double.random(in: 0.05...0.35),
                phase: Double.random(in: 0...10),
                xSpan: Double.random(in: 0.4...1.0),
                ySpan: Double.random(in: 0.4...1.0),
                xOffset: Double.random(in: -0.1...0.1),
                yOffset: Double.random(in: -0.1...0.1),
                flicker: Double.random(in: 0.6...2.4),
                color: palette.randomElement()!
            )
        }
    }
}
