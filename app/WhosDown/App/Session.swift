import Foundation

/// Who is signed in and whether they still need onboarding; drives `RootView`.
/// 1.3 adds `requireAccount(then:)` for the Guest gate.
@Observable
final class Session {
    enum State: Equatable {
        case loading
        case signedOut
        /// A Player or a Guest is signed in; the tab bar shows.
        case active
    }

    private(set) var state: State = .loading
    private(set) var user: AuthUser?
    /// The signed-in Player's profile, kept live. Nil for Guests and while it loads.
    private(set) var profile: UserProfile?
    private(set) var profileLoaded = false

    private let auth: AuthRepository
    private let users: UserRepository
    private var profileTask: Task<Void, Never>?

    init(auth: AuthRepository, users: UserRepository) {
        self.auth = auth
        self.users = users
    }

    var isGuest: Bool { user?.isGuest ?? false }

    /// A signed-in Player whose profile has no `onboardedAt` yet (1.2 rule 2, 1.4 rule 8).
    var needsOnboarding: Bool {
        guard let user, !user.isGuest, profileLoaded else { return false }
        return profile?.onboardedAt == nil
    }

    /// Follows sign-in changes for the life of the app.
    func start() async {
        for await user in auth.authStateChanges() {
            apply(user)
        }
    }

    private func apply(_ user: AuthUser?) {
        profileTask?.cancel()
        self.user = user
        profile = nil
        profileLoaded = false
        guard let user else {
            state = .signedOut
            return
        }
        state = .active
        guard !user.isGuest else { return }
        profileTask = Task { [users] in
            do {
                for try await profile in users.profileChanges(userId: user.id) {
                    guard !Task.isCancelled else { return }
                    self.profile = profile
                    self.profileLoaded = true
                }
            } catch {
                // Listener failed (e.g. signed out mid-stream); the next auth change resets it.
            }
        }
    }
}
