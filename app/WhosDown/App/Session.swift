import Foundation

/// Who is signed in, whether they still need onboarding, and the Guest gate (1.3). Drives `RootView`.
@Observable
final class Session {
    enum State: Equatable {
        case loading
        case signedOut
        /// A Player or a Guest is signed in; the tab bar shows.
        case active
    }

    /// Which screen the Guest gate (H34) opens on.
    enum GateRoute: Hashable {
        case choose, createAccount, signIn
    }

    private(set) var state: State = .loading
    private(set) var user: AuthUser?
    /// The signed-in Player's profile, kept live. Nil for Guests and while it loads.
    private(set) var profile: UserProfile?
    private(set) var profileLoaded = false
    /// Non-nil while the Guest gate sheet is showing.
    var gateRoute: GateRoute?

    private let auth: AuthRepository
    private let users: UserRepository
    private let defaults: UserDefaults
    private var profileTask: Task<Void, Never>?

    init(auth: AuthRepository, users: UserRepository, defaults: UserDefaults = .standard) {
        self.auth = auth
        self.users = users
        self.defaults = defaults
    }

    var isGuest: Bool { user?.isGuest ?? false }

    /// A signed-in Player whose profile has no `onboardedAt` yet (1.2 rule 2, 1.4 rule 8).
    var needsOnboarding: Bool {
        guard let user, !user.isGuest, profileLoaded else { return false }
        return profile?.onboardedAt == nil
    }

    /// Every action a Guest can't take goes through here (1.3 rule 2): Guests get the gate and nothing runs.
    func requireAccount(then action: () -> Void) {
        if isGuest {
            gateRoute = .choose
        } else {
            action()
        }
    }

    func showGate(_ route: GateRoute = .choose) {
        gateRoute = route
    }

    /// Follows sign-in changes for the life of the app.
    func start() async {
        // Firebase keeps the sign-in in the Keychain, which survives deleting the app; UserDefaults doesn't.
        // So the first launch after an install signs out any leftover account (1.3 rule 7).
        if !defaults.bool(forKey: Self.hasLaunchedKey) {
            try? auth.signOut()
            defaults.set(true, forKey: Self.hasLaunchedKey)
        }
        for await user in auth.authStateChanges() {
            // Token refreshes repeat the same user; only real changes reset state.
            guard state == .loading || user != self.user else { continue }
            apply(user)
        }
    }

    private static let hasLaunchedKey = "hasLaunchedBefore"

    private func apply(_ user: AuthUser?) {
        profileTask?.cancel()
        self.user = user
        profile = nil
        profileLoaded = false
        if user?.isGuest != true { gateRoute = nil }
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
