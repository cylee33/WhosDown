import Foundation

/// H02 Create account (1.2). Creates the Auth user, then the profile and settings (W1).
/// Session then routes the new Player to onboarding.
@Observable
final class CreateAccountViewModel {
    var email = ""
    var password = ""
    var displayName = ""
    private(set) var isWorking = false
    private(set) var errorMessage: String?
    /// Shown under a field once the Player has tried to continue.
    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var nameError: String?

    private let auth: AuthRepository
    private let users: UserRepository

    init(auth: AuthRepository, users: UserRepository) {
        self.auth = auth
        self.users = users
    }

    func createAccount() async {
        guard !isWorking else { return }
        errorMessage = nil
        let email = email.trimmingCharacters(in: .whitespaces)
        emailError = AccountRules.isValidEmail(email) ? nil : AuthError.invalidEmail.message
        passwordError = AccountRules.isValidPassword(password) ? nil : AuthError.weakPassword.message
        let name = AccountRules.cleanedDisplayName(displayName)
        nameError = name == nil ? "Enter a name of up to \(AccountRules.displayNameLimit) characters." : nil
        guard emailError == nil, passwordError == nil, let name else { return }

        isWorking = true
        defer { isWorking = false }
        do {
            let user = try await auth.createAccount(email: email, password: password)
            try await users.createProfile(userId: user.id, displayName: name, email: email)
        } catch let error as AuthError {
            errorMessage = error.message
        } catch {
            errorMessage = AuthError.unknown.message
        }
    }
}
