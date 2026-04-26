import SwiftUI

/// `StatusPillView` is the always-visible top pill that mimics how Telegram
/// (and other large messengers) draw their own in-app notch overlay. It is
/// **not** an ActivityKit Live Activity — those don't render inside a
/// running app on iPhones without Dynamic Island. We draw it ourselves.
///
/// The pill sits just below the system notch / status bar, animated in with
/// a spring on app launch. Tapping it expands into a small action card with
/// "Stop" / "Configure" buttons and collapses again on outside-tap.
///
/// All chrome uses `.ultraThinMaterial` so the pill picks up colour from the
/// background — closest possible approximation to Apple's Liquid Glass given
/// that the real material API ships only with iOS 26 SDK.
struct StatusPillView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var expanded: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var content: some View {
        if expanded {
            expandedCard
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .top)
                        .combined(with: .opacity),
                    removal: .scale(scale: 0.94, anchor: .top)
                        .combined(with: .opacity)
                ))
        } else {
            collapsedPill
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Collapsed pill

    private var collapsedPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.success)
                .frame(width: 6, height: 6)
                .opacity(appeared ? 1 : 0.4)
                .scaleEffect(appeared ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                           value: appeared)
            Text(settings.liveActivityText.isEmpty ? "@MaksimXyila" : settings.liveActivityText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 3)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.4)) {
                appeared = true
            }
        }
        .onTapGesture {
            Haptics.light()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                expanded = true
            }
        }
        .accessibilityLabel("Status pill: \(settings.liveActivityText)")
    }

    // MARK: - Expanded card

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(AppTheme.success).frame(width: 6, height: 6)
                Text(settings.liveActivityText.isEmpty ? "@MaksimXyila" : settings.liveActivityText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        expanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(6)
                }
            }
            Text("In-app статус-баннер. Настроить текст или выключить можно в настройках → Live Activity.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 14, y: 6)
        .padding(.horizontal, 16)
    }
}
