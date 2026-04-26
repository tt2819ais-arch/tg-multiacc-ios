import SwiftUI

/// `PressInteractiveStyle` is the app-wide button style that gives a tactile,
/// iOS-26-flavoured feel to every primary interaction:
///
///   * a confident scale-down on press (spring, never abrupt)
///   * a soft white halo that expands from underneath the label and fades out
///   * a haptic tick when the press starts and a slightly stronger one if the
///     press is held long enough that the system would consider it confirmed
///
/// The style is intentionally subtle — no rainbows, no animated borders. It
/// just makes the touch feel "real".
struct PressInteractiveStyle: ButtonStyle {
    var fill: Color = AppTheme.accent
    var foreground: Color? = nil
    var disabled: Bool = false
    /// Vertical padding of the button label.
    var verticalPadding: CGFloat = 14
    /// Corner radius of the button itself.
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        let fg: Color = foreground ?? (AppTheme.palette.isLight ? .white : .black)
        return configuration.label
            .font(AppTheme.headline(16))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(disabled ? fill.opacity(0.35) : fill)
            )
            .overlay(
                PressHaloOverlay(active: configuration.isPressed,
                                 cornerRadius: cornerRadius)
                    .allowsHitTesting(false)
            )
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.72),
                       value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { Haptics.light() }
            }
    }
}

/// A glow that grows out from the button while it is being pressed and decays
/// once the press ends. Implemented with a single `RoundedRectangle` overlay so
/// it stays cheap on the GPU.
struct PressHaloOverlay: View {
    var active: Bool
    var cornerRadius: CGFloat = 14

    @State private var phase: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.white.opacity(active ? 0.5 : 0.0), lineWidth: 1.5)
            .blur(radius: 0.5)
            .scaleEffect(active ? 1.04 + (phase * 0.025) : 1.0)
            .opacity(active ? max(0, 1 - phase) : 0)
            .animation(.easeOut(duration: 0.45), value: active)
            .onChange(of: active) { isActive in
                if isActive {
                    phase = 0
                    withAnimation(.easeOut(duration: 0.55)) { phase = 1 }
                }
            }
    }
}

/// A surface-style press effect for cards and rows: lighter scale, softer halo,
/// subtle highlight tint. Use this on tappable rows where a full coloured fill
/// would be visually too loud.
struct SurfacePressStyle: ButtonStyle {
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.05 : 0.0))
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.78),
                       value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { Haptics.selection() }
            }
    }
}
