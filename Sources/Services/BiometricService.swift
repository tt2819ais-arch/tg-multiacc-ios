import Foundation
import LocalAuthentication
import SwiftUI

/// Simple wrapper around LAContext that gates app entry behind Face ID /
/// Touch ID when the corresponding setting is enabled.
@MainActor
final class BiometricService: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var lastError: String?

    var biometryType: LABiometryType {
        let ctx = LAContext()
        var err: NSError?
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        return ctx.biometryType
    }

    var biometryName: String {
        let t = biometryType
        if t == .faceID { return "Face ID" }
        if t == .touchID { return "Touch ID" }
        if #available(iOS 17.0, *), t == .opticID { return "Optic ID" }
        return "Biometrics"
    }

    var isAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    func authenticate(reason: String) async {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use passcode"
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthentication,
                                                  localizedReason: reason)
            isUnlocked = ok
            lastError = ok ? nil : "Authentication failed"
        } catch {
            isUnlocked = false
            lastError = error.localizedDescription
        }
    }

    func lock() {
        isUnlocked = false
    }
}
