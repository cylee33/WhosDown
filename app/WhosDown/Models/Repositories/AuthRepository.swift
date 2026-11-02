import FirebaseAuth
import Foundation

/// Sign-in state and actions. 1.2 adds create account and password reset; 1.3 adds Guest sign-in.
protocol AuthRepository {
    var currentUserId: String? { get }
    /// Emits the signed-in user's ID, or nil when signed out, now and on every change.
    func authStateChanges() -> AsyncStream<String?>
    func signIn(email: String, password: String) async throws
    func signOut() throws
}

final class FirebaseAuthRepository: AuthRepository {
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    func authStateChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            }
            continuation.onTermination = { _ in
                Task { @MainActor in Auth.auth().removeStateDidChangeListener(handle) }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
