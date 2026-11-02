import Foundation

/// H41 Sign in and password reset (1.2).
@Observable
final class SignInViewModel {
    var email = ""
    var password = ""
    private(set) var isWorking = false
    private(set) var errorMessage: String?
    private(set) var resetMessage: String?

    static let resetSentMessage = "If an account exists for that email, we sent a reset link."

    private let auth: AuthRepository

    init(auth: AuthRepository) {
        self.auth = auth
    }

    func signIn() async {
        guard !isWorking else { return }
        resetMessage = nil
        let email = email.trimmingCharacters(in: .whitespaces)
        guard AccountRules.isValidEmail(email), !password.isEmpty else {
            errorMessage = AuthError.wrongCredentials.message
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await auth.signIn(email: email, password: password)
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = error.message
        } catch {
            errorMessage = AuthError.unknown.message
        }
    }

    /// Always gives the same answer whether or not the account exists (1.2 rule 5); only "offline" differs.
    func sendPasswordReset() async {
        guard !isWorking else { return }
        errorMessage = nil
        let email = email.trimmingCharacters(in: .whitespaces)
        guard AccountRules.isValidEmail(email) else {
            errorMessage = "Type your email above first."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await auth.sendPasswordReset(email: email)
            resetMessage = Self.resetSentMessage
        } catch AuthError.network {
            errorMessage = AuthError.network.message
        } catch {
            resetMessage = Self.resetSentMessage
        }
    }
}
