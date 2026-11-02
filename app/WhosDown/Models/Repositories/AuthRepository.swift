import FirebaseAuth
import Foundation

/// The signed-in account. A Guest is signed in anonymously (1.3).
nonisolated struct AuthUser: Equatable, Sendable {
    let id: String
    let isGuest: Bool
}

/// Sign-in failures as plain sentences (1.2 rule 4). Never show raw Firebase codes.
nonisolated enum AuthError: Error, Equatable {
    case emailInUse, wrongCredentials, invalidEmail, weakPassword, network, tooManyAttempts, unknown

    var message: String {
        switch self {
        case .emailInUse: "That email is already in use. Sign in instead?"
        case .wrongCredentials: "Wrong email or password."
        case .invalidEmail: "That doesn't look like an email address."
        case .weakPassword: "Use at least 8 characters for your password."
        case .network: "No internet connection."
        case .tooManyAttempts: "Too many tries. Wait a minute and try again."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}

/// Sign-in state and actions.
protocol AuthRepository {
    var currentUser: AuthUser? { get }
    /// Emits the signed-in account, or nil when signed out, now and on every change.
    func authStateChanges() -> AsyncStream<AuthUser?>
    /// Creates an email account and signs in. Throws `AuthError`.
    func createAccount(email: String, password: String) async throws -> AuthUser
    /// Throws `AuthError`.
    func signIn(email: String, password: String) async throws
    /// Throws `AuthError` (only `.network` matters to callers, 1.2 rule 5).
    func sendPasswordReset(email: String) async throws
    func signOut() throws
    /// Anonymous sign-in for browsing without an account (1.3). Throws `AuthError`.
    func signInAsGuest() async throws
    /// Turns the current Guest into an email account, keeping the same user ID (1.3 rule 3). Throws `AuthError`.
    func linkGuestAccount(email: String, password: String) async throws -> AuthUser
}

final class FirebaseAuthRepository: AuthRepository {
    var currentUser: AuthUser? { Auth.auth().currentUser.map(Self.authUser) }

    func authStateChanges() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            // The ID-token listener also fires when a Guest links an email account (same user, new provider).
            let handle = Auth.auth().addIDTokenDidChangeListener { _, user in
                continuation.yield(user.map(Self.authUser))
            }
            continuation.onTermination = { _ in
                Task { @MainActor in Auth.auth().removeIDTokenDidChangeListener(handle) }
            }
        }
    }

    func createAccount(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return Self.authUser(result.user)
        } catch {
            throw Self.authError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw Self.authError(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw Self.authError(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func signInAsGuest() async throws {
        do {
            try await Auth.auth().signInAnonymously()
        } catch {
            throw Self.authError(error)
        }
    }

    func linkGuestAccount(email: String, password: String) async throws -> AuthUser {
        guard let user = Auth.auth().currentUser, user.isAnonymous else { throw AuthError.unknown }
        do {
            let result = try await user.link(with: EmailAuthProvider.credential(withEmail: email, password: password))
            // Refresh the token so security rules see the password provider, not "anonymous", on the next write.
            _ = try await result.user.getIDTokenResult(forcingRefresh: true)
            return Self.authUser(result.user)
        } catch {
            throw Self.authError(error)
        }
    }

    nonisolated private static func authUser(_ user: User) -> AuthUser {
        AuthUser(id: user.uid, isGuest: user.isAnonymous)
    }

    private static func authError(_ error: Error) -> AuthError {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .emailAlreadyInUse, .credentialAlreadyInUse: .emailInUse
        case .wrongPassword, .invalidCredential, .userNotFound: .wrongCredentials
        case .invalidEmail: .invalidEmail
        case .weakPassword: .weakPassword
        case .networkError: .network
        case .tooManyRequests: .tooManyAttempts
        default: .unknown
        }
    }
}
