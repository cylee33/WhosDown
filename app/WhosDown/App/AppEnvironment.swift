import SwiftUI

/// The one dependency container (ADR-0001, 1.1 rule 4). Views get it from the SwiftUI environment
/// and hand repositories to their view models. Features add their repositories here.
@Observable
final class AppEnvironment {
    let auth: AuthRepository
    let users: UserRepository
    let matches: MatchRepository
    let permissions: PermissionsService

    init(auth: AuthRepository, users: UserRepository, matches: MatchRepository, permissions: PermissionsService) {
        self.auth = auth
        self.users = users
        self.matches = matches
        self.permissions = permissions
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            auth: FirebaseAuthRepository(), users: FirebaseUserRepository(),
            matches: FirebaseMatchRepository(), permissions: SystemPermissionsService()
        )
    }

    static func preview(signedInAs userId: String? = "seed_alex") -> AppEnvironment {
        AppEnvironment(
            auth: FakeAuthRepository(signedInAs: userId), users: FakeUserRepository(),
            matches: FakeMatchRepository(), permissions: FakePermissionsService()
        )
    }
}
