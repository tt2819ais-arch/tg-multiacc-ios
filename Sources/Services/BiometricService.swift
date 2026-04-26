import Foundation
import LocalAuthentication
import CryptoKit
import SwiftUI

/// Combined biometric + PIN unlock service. Always exposes a usable state
/// so the UI can never end up on a blank screen — failures are surfaced
/// as `lastError` and the lock view stays visible with retry / fallback.
@MainActor
final class BiometricService: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var lastError: String?
    @Published var failedAttempts: Int = 0

    private let pinKeychainKey = "app_lock_pin_sha256"

    // MARK: - Biometrics

    var biometryType: LABiometryType {
        let ctx = LAContext()
        var err: NSError?
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        return ctx.biometryType
    }

    var biometryName: String {
        switch biometryType {
        case .faceID:                 return "Face ID"
        case .touchID:                return "Touch ID"
        default:
            if #available(iOS 17.0, *), biometryType == .opticID { return "Optic ID" }
            return "Biometrics"
        }
    }

    var systemBiometricsAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    /// Whether biometric auth can be used right now. Falls back to passcode
    /// if biometrics are unavailable so the user is never permanently locked
    /// out.
    var canAttemptBiometrics: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err)
    }

    func authenticate(reason: String) async {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Использовать пароль устройства"
        ctx.localizedCancelTitle = "Отмена"
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthentication,
                                                  localizedReason: reason)
            if ok {
                isUnlocked = true
                lastError = nil
                failedAttempts = 0
                Haptics.success()
            } else {
                failedAttempts += 1
                lastError = "Не удалось подтвердить личность"
                Haptics.error()
            }
        } catch let err as LAError {
            failedAttempts += 1
            lastError = humanReadable(err)
            Haptics.error()
        } catch {
            failedAttempts += 1
            lastError = error.localizedDescription
            Haptics.error()
        }
    }

    private func humanReadable(_ err: LAError) -> String {
        switch err.code {
        case .userCancel, .appCancel, .systemCancel:
            return "Отменено"
        case .userFallback:
            return "Выбран запасной способ"
        case .biometryNotAvailable:
            return "Биометрия недоступна на устройстве"
        case .biometryNotEnrolled:
            return "Face ID/Touch ID не настроены в системе"
        case .biometryLockout:
            return "Биометрия временно заблокирована — введите код устройства"
        case .passcodeNotSet:
            return "На устройстве не задан код-пароль"
        case .authenticationFailed:
            return "Лицо/отпечаток не распознаны"
        default:
            return err.localizedDescription
        }
    }

    func lock() {
        isUnlocked = false
    }

    // MARK: - PIN

    var hasPin: Bool {
        Keychain.getData(forKey: pinKeychainKey) != nil
    }

    func setPin(_ pin: String) {
        guard pin.count >= 4 else { return }
        let hash = Self.sha256(pin)
        _ = Keychain.setData(hash, forKey: pinKeychainKey)
        Haptics.success()
    }

    func clearPin() {
        Keychain.delete(forKey: pinKeychainKey)
    }

    @discardableResult
    func verifyPin(_ pin: String) -> Bool {
        guard let stored = Keychain.getData(forKey: pinKeychainKey) else { return false }
        let candidate = Self.sha256(pin)
        let ok = stored == candidate
        if ok {
            isUnlocked = true
            lastError = nil
            failedAttempts = 0
            Haptics.success()
        } else {
            failedAttempts += 1
            lastError = "Неверный PIN"
            Haptics.error()
        }
        return ok
    }

    private static func sha256(_ value: String) -> Data {
        let digest = SHA256.hash(data: Data(value.utf8))
        return Data(digest)
    }
}

// Backwards-compat aliases used by existing code.
extension BiometricService {
    var isAvailable: Bool { canAttemptBiometrics }
}
