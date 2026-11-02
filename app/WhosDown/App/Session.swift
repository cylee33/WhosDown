import Foundation

/// Who is signed in, for routing between the Welcome screen and the tab bar.
/// 1.3 adds `isGuest` and `requireAccount(then:)`.
@Observable
final class Session {
    enum State: Equatable {
        case loading
        case signedOut
        case signedIn(userId: String)
    }

    private(set) var state: State = .loading
    private let auth: AuthRepository

    init(auth: AuthRepository) {
        self.auth = auth
    }

    /// Follows sign-in changes for the life of the app.
    func start() async {
        for await userId in auth.authStateChanges() {
            state = userId.map { .signedIn(userId: $0) } ?? .signedOut
        }
    }
}
