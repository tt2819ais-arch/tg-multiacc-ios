import SwiftUI

/// Two-step PIN setup: enter, confirm. Used from Settings to configure or
/// change the application PIN.
struct PinSetupView: View {
    @EnvironmentObject var biometrics: BiometricService
    @Environment(\.dismiss) private var dismiss

    enum Step { case enter, confirm }
    @State private var step: Step = .enter
    @State private var first: String = ""
    @State private var current: String = ""
    @State private var error: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer(minLength: 16)
                Image(systemName: "number.square")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accent)
                Text(step == .enter ? "Придумай PIN" : "Повтори PIN")
                    .font(AppTheme.title(22))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(step == .enter ? "4 цифры" : "Чтобы убедиться, что не опечатался")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
                if let err = error {
                    Text(err)
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.danger)
                }
                PinPad(value: $current, length: 4, accent: AppTheme.accent) { typed in
                    handle(typed)
                }
                Spacer()
                Button("Отменить") {
                    Haptics.selection()
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }

    private func handle(_ typed: String) {
        switch step {
        case .enter:
            first = typed
            current = ""
            step = .confirm
            error = nil
        case .confirm:
            if typed == first {
                biometrics.setPin(typed)
                Haptics.success()
                dismiss()
            } else {
                error = "PIN не совпал — попробуй заново"
                first = ""
                current = ""
                step = .enter
                Haptics.error()
            }
        }
    }
}
