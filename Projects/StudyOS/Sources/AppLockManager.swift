import Core
import LocalAuthentication
import SwiftUI

@MainActor
final class AppLockManager: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var lastErrorMessage: String?

    func lockIfNeeded() {
        guard isEnabled else {
            isLocked = false
            return
        }
        isLocked = true
    }

    func disableLock() {
        isLocked = false
    }

    func unlockIfNeeded() async {
        guard isEnabled else {
            isLocked = false
            return
        }

        do {
            let unlocked = try await evaluatePolicy()
            isLocked = !unlocked
        } catch {
            lastErrorMessage = error.localizedDescription
            isLocked = true
        }
    }

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppConstants.appLockEnabledKey)
    }

    private func evaluatePolicy() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true
        }
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock StudyOS") { success, authError in
                if let authError {
                    continuation.resume(throwing: authError)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
