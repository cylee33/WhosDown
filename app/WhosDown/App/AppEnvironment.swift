import SwiftUI

/// The one dependency container (ADR-0001, 1.1 rule 4). Views get it from the SwiftUI environment
/// and hand repositories to their view models. Features add their repositories here.
@Observable
final class AppEnvironment {
    let auth: AuthRepository
    let matches: MatchRepository

    init(auth: AuthRepository, matches: MatchRepository) {
        self.auth = auth
        self.matches = matches
    }

    static func live() -> AppEnvironment {
        AppEnvironment(auth: FirebaseAuthRepository(), matches: FirebaseMatchRepository())
    }

    static func preview(signedInAs userId: String? = "seed_alex") -> AppEnvironment {
        AppEnvironment(auth: FakeAuthRepository(signedInAs: userId), matches: FakeMatchRepository())
    }
}
