import SwiftUI

/// Themed text field used across forms.
struct ThemedTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var secure: Bool = false
    var autocap: TextInputAutocapitalization = .never
    var autocorrect: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)
            }
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(autocap)
            .autocorrectionDisabled(!autocorrect)
            .keyboardType(keyboard)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .foregroundStyle(AppTheme.textPrimary)
            .font(AppTheme.body(16))
        }
    }
}

/// Card row used in the bulk-action menu.
struct ActionCardRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTheme.headline(16)).foregroundStyle(AppTheme.textPrimary)
                Text(subtitle).font(AppTheme.body(13)).foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(AppTheme.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
    }
}

struct ProgressBar: View {
    var done: Int
    var total: Int

    var body: some View {
        let pct = total == 0 ? 0 : Double(done) / Double(total)
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.surfaceElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [AppTheme.accent, AppTheme.success],
                                              startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * pct))
                        .animation(.easeInOut(duration: 0.2), value: pct)
                }
            }
            .frame(height: 8)
            HStack {
                Text("\(done) / \(total)").font(AppTheme.mono()).foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(Int(pct * 100))%").font(AppTheme.mono()).foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct ResultsList: View {
    var results: [BulkActionResult]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(results) { r in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: r.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(r.success ? AppTheme.success : AppTheme.danger)
                        .font(.system(size: 18, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.accountLabel).font(AppTheme.headline(14)).foregroundStyle(AppTheme.textPrimary)
                        Text(r.detail).font(AppTheme.body(12)).foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.separator, lineWidth: 1))
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let action: (label: String, run: () -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(AppTheme.headline(16))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let a = action {
                Button(a.label, action: a.run)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

extension AccountAuthState {
    var statusBadge: (text: String, color: Color) {
        switch self {
        case .ready:           return ("ready", AppTheme.success)
        case .loading:         return ("connecting", AppTheme.warning)
        case .waitPhoneNumber: return ("phone", AppTheme.warning)
        case .waitCode:        return ("code", AppTheme.warning)
        case .waitPassword:    return ("2FA", AppTheme.warning)
        case .waitRegistration:return ("register", AppTheme.warning)
        case .loggedOut:       return ("signed out", AppTheme.danger)
        case .closed:          return ("closed", AppTheme.danger)
        case .error:           return ("error", AppTheme.danger)
        }
    }
}
