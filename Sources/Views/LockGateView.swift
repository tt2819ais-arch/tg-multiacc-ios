import SwiftUI
import LocalAuthentication

/// Always-visible lock screen. Combines biometric prompt and PIN keypad
/// based on `SettingsStore.lockMode`. Designed to never leave the user
/// staring at a blank screen — there is always a clearly-labeled action
/// available (retry, switch to PIN, emergency disable).
struct LockGateView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var biometrics: BiometricService

    @State private var showingPin: Bool = false
    @State private var pinDraft: String = ""
    @State private var didAutoTry: Bool = false
    @State private var showResetAlert: Bool = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 40)

                Image(systemName: iconName)
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.bottom, 4)

                Text("TG MULTIACC")
                    .font(AppTheme.title(26))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Заблокировано")
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.textSecondary)

                if let err = biometrics.lastError {
                    Text(err)
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer(minLength: 8)

                if showingPin || onlyPinMode {
                    PinPad(value: $pinDraft, accent: AppTheme.accent) { typed in
                        let ok = biometrics.verifyPin(typed)
                        if !ok { pinDraft = "" }
                    }
                    .padding(.horizontal, 24)
                } else {
                    primaryActions
                }

                Spacer(minLength: 16)

                fallbackBar
                    .padding(.bottom, 24)
            }
            .padding(.top, 40)
            .padding(.horizontal, 16)
        }
        .alert("Сбросить замок приложения?",
               isPresented: $showResetAlert,
               actions: {
            Button("Отменить", role: .cancel) {}
            Button("Сбросить", role: .destructive) {
                settings.lockMode = .off
                biometrics.clearPin()
                biometrics.isUnlocked = true
                Haptics.warning()
            }
        }, message: {
            Text("Это полностью отключит блокировку. Включить обратно можно в настройках.")
        })
        .onAppear { autoTryIfNeeded() }
    }

    private var iconName: String {
        if onlyPinMode { return "lock.fill" }
        switch biometrics.biometryType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:
            if #available(iOS 17.0, *), biometrics.biometryType == .opticID { return "opticid" }
            return "lock.fill"
        }
    }

    private var onlyPinMode: Bool {
        settings.lockMode == .pin || (settings.lockMode == .biometricThenPin && !biometrics.systemBiometricsAvailable)
            || (settings.lockMode == .biometric && !biometrics.canAttemptBiometrics && biometrics.hasPin)
    }

    private var primaryActions: some View {
        VStack(spacing: 12) {
            if biometrics.canAttemptBiometrics && settings.lockMode.requiresBiometric {
                Button {
                    Haptics.light()
                    Task { await biometrics.authenticate(reason: "Разблокируй TG MULTIACC") }
                } label: {
                    Label("Войти через \(biometrics.biometryName)",
                          systemImage: biometrics.biometryType == .faceID ? "faceid" : "lock.shield")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            if biometrics.hasPin {
                Button {
                    Haptics.selection()
                    showingPin = true
                } label: {
                    Label("Ввести PIN", systemImage: "number.square")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }

    private var fallbackBar: some View {
        VStack(spacing: 8) {
            if biometrics.failedAttempts >= 3 {
                Text("Если не получается войти — сбрось замок и зайди в настройки.")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text("Сбросить замок")
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.danger)
                }
            }
        }
    }

    private func autoTryIfNeeded() {
        guard !didAutoTry else { return }
        didAutoTry = true
        if settings.lockMode.requiresBiometric, biometrics.canAttemptBiometrics {
            Task { await biometrics.authenticate(reason: "Разблокируй TG MULTIACC") }
        } else if settings.lockMode == .pin {
            showingPin = true
        }
    }
}

/// 6-digit PIN keypad. Calls `onComplete` once `length` digits are typed.
struct PinPad: View {
    @Binding var value: String
    var length: Int = 4
    var accent: Color
    var onComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 14) {
                ForEach(0..<length, id: \.self) { idx in
                    Circle()
                        .fill(idx < value.count ? accent : AppTheme.surfaceElevated)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                }
            }
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { col in
                            digitButton("\(row * 3 + col)")
                        }
                    }
                }
                HStack(spacing: 12) {
                    placeholderKey
                    digitButton("0")
                    backspaceButton
                }
            }
        }
    }

    private func digitButton(_ digit: String) -> some View {
        Button {
            guard value.count < length else { return }
            Haptics.selection()
            value.append(digit)
            if value.count == length {
                onComplete(value)
            }
        } label: {
            Text(digit)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 76, height: 76)
                .background(
                    Circle().fill(AppTheme.surfaceElevated)
                )
                .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var backspaceButton: some View {
        Button {
            guard !value.isEmpty else { return }
            Haptics.light()
            value.removeLast()
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 76, height: 76)
        }
        .buttonStyle(.plain)
    }

    private var placeholderKey: some View {
        Color.clear.frame(width: 76, height: 76)
    }
}
