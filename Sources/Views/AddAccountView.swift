import SwiftUI

struct AddAccountView: View {
    @ObservedObject var account: TelegramAccount
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var busy: Bool = false

    var l: L10n { settings.l10n }

    var body: some View {
        NavigationStack {
            ZStack {
                settings.theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        switch account.authState {
                        case .loading:
                            statusCard(text: "Connecting to Telegram…")
                        case .waitPhoneNumber:
                            phoneSection
                        case .waitCode(let phoneNumber, let info):
                            codeSection(phone: phoneNumber, info: info)
                        case .waitPassword(let hint):
                            passwordSection(hint: hint)
                        case .waitRegistration:
                            registrationSection
                        case .ready:
                            statusCard(text: l.t("add.ready"), tint: AppTheme.success)
                        case .error(let msg):
                            statusCard(text: msg, tint: AppTheme.danger)
                        case .loggedOut, .closed:
                            statusCard(text: "Session ended", tint: AppTheme.danger)
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(l.t("add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(l.t("add.cancel")) { dismiss() }
                        .foregroundStyle(AppTheme.danger)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if account.authState.isReady {
                        Button(l.t("common.close")) { dismiss() }
                    }
                }
            }
            .onChange(of: account.authState) { newValue in
                if case .ready = newValue {
                    // Auto-dismiss after a short delay so user sees success state.
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        await MainActor.run { dismiss() }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(settings.theme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(account.lastTdAuthorizationState)
                .font(AppTheme.mono(11))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ThemedTextField(title: l.t("add.phone"),
                            text: $phone,
                            placeholder: l.t("add.phone.placeholder"),
                            keyboard: .phonePad,
                            autocap: .never,
                            autocorrect: false)
            Button(l.t("add.phone.send")) { Task { await submitPhone() } }
                .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                disabled: !canSubmitPhone || busy))
                .disabled(!canSubmitPhone || busy)
        }
    }

    private func codeSection(phone: String, info: String?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(l.t("add.code.info", phone))
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textSecondary)
            if let info { Text(info).font(AppTheme.mono(11)).foregroundStyle(AppTheme.textTertiary) }
            ThemedTextField(title: l.t("add.code"),
                            text: $code,
                            placeholder: l.t("add.code.placeholder"),
                            keyboard: .numberPad,
                            autocap: .never,
                            autocorrect: false)
            Button(l.t("add.code.confirm")) { Task { await submitCode() } }
                .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                disabled: code.count < 4 || busy))
                .disabled(code.count < 4 || busy)
        }
    }

    private func passwordSection(hint: String?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let h = hint, !h.isEmpty {
                Text(l.t("add.password.hint", h))
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            ThemedTextField(title: l.t("add.password"),
                            text: $password,
                            placeholder: l.t("add.password.placeholder"),
                            secure: true)
            Button(l.t("add.password.confirm")) { Task { await submitPassword() } }
                .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                disabled: password.isEmpty || busy))
                .disabled(password.isEmpty || busy)
        }
    }

    private var registrationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ThemedTextField(title: l.t("add.register.first"), text: $firstName)
            ThemedTextField(title: l.t("add.register.last"), text: $lastName)
            Button(l.t("add.register.confirm")) { Task { await submitRegistration() } }
                .buttonStyle(PrimaryButtonStyle(fill: settings.theme.accent,
                                                disabled: firstName.isEmpty || busy))
                .disabled(firstName.isEmpty || busy)
        }
    }

    private func statusCard(text: String, tint: Color = AppTheme.warning) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(tint)
            Text(text).font(AppTheme.body(14)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .card()
    }

    // MARK: - Submit

    private var canSubmitPhone: Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 7
    }

    private func submitPhone() async {
        busy = true; defer { busy = false }
        await account.submitPhone(phone)
    }

    private func submitCode() async {
        busy = true; defer { busy = false }
        await account.submitCode(code)
    }

    private func submitPassword() async {
        busy = true; defer { busy = false }
        await account.submitPassword(password)
    }

    private func submitRegistration() async {
        busy = true; defer { busy = false }
        await account.submitRegistration(firstName: firstName, lastName: lastName)
    }
}
