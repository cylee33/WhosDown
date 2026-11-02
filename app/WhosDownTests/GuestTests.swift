import Foundation
import Testing
@testable import WhosDown

/// 1.3 Guest browsing.
@MainActor
struct GuestTests {
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test func exploreAsGuestSignsInAnonymously() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        let viewModel = WelcomeViewModel(auth: auth)
        await viewModel.exploreAsGuest()
        #expect(auth.calls == ["signInAsGuest"])
        #expect(auth.currentUser?.isGuest == true)
    }

    @Test func gateBlocksGuestActionsAndLetsPlayersThrough() async {
        let auth = FakeAuthRepository(signedInAs: "guest_1", isGuest: true)
        let session = Session(auth: auth, users: FakeUserRepository(), defaults: .launchedBefore)
        let task = Task { await session.start() }
        defer { task.cancel() }
        await settle()

        var ran = false
        session.requireAccount { ran = true }
        #expect(!ran)
        #expect(session.gateRoute == .choose)

        let playerAuth = FakeAuthRepository(signedInAs: "seed_alex")
        let playerSession = Session(auth: playerAuth, users: FakeUserRepository(), defaults: .launchedBefore)
        let playerTask = Task { await playerSession.start() }
        defer { playerTask.cancel() }
        await settle()
        playerSession.requireAccount { ran = true }
        #expect(ran)
        #expect(playerSession.gateRoute == nil)
    }

    @Test func guestHasNoProfileAndNoOnboarding() async {
        let auth = FakeAuthRepository(signedInAs: "guest_1", isGuest: true)
        let session = Session(auth: auth, users: FakeUserRepository(profiles: [:]), defaults: .launchedBefore)
        let task = Task { await session.start() }
        defer { task.cancel() }
        await settle()
        #expect(session.state == .active)
        #expect(session.isGuest)
        #expect(session.profile == nil)
        #expect(!session.needsOnboarding)
    }

    @Test func createAccountAsGuestLinksKeepingTheIdThenOnboards() async {
        let auth = FakeAuthRepository(signedInAs: "guest_1", isGuest: true)
        let users = FakeUserRepository(profiles: [:])
        let session = Session(auth: auth, users: users, defaults: .launchedBefore)
        let task = Task { await session.start() }
        defer { task.cancel() }
        await settle()
        session.showGate(.createAccount)

        let viewModel = CreateAccountViewModel(auth: auth, users: users)
        viewModel.email = "alex@cmu.edu"
        viewModel.password = "whosdown123"
        viewModel.displayName = "Alex"
        await viewModel.createAccount()
        await settle()

        #expect(auth.calls == ["linkGuestAccount"])
        #expect(users.createdProfiles.first?.userId == "guest_1")
        #expect(session.user == AuthUser(id: "guest_1", isGuest: false))
        #expect(session.gateRoute == nil)
        #expect(session.needsOnboarding)
    }

    @Test func firstLaunchAfterInstallSignsOutALeftoverAccount() async {
        let defaults = UserDefaults(suiteName: "SessionTests-\(UUID().uuidString)")!
        let auth = FakeAuthRepository(signedInAs: "seed_alex")
        let session = Session(auth: auth, users: FakeUserRepository(), defaults: defaults)
        let task = Task { await session.start() }
        await settle()
        task.cancel()
        #expect(session.state == .signedOut)

        // Later launches keep the session (1.2 rule 8).
        try? await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        let relaunched = Session(auth: auth, users: FakeUserRepository(), defaults: defaults)
        let relaunchTask = Task { await relaunched.start() }
        defer { relaunchTask.cancel() }
        await settle()
        #expect(relaunched.state == .active)
    }
}

extension UserDefaults {
    /// A fresh store that says the app has launched before, so `Session` keeps the signed-in account.
    static var launchedBefore: UserDefaults {
        let defaults = UserDefaults(suiteName: "launched-\(UUID().uuidString)")!
        defaults.set(true, forKey: "hasLaunchedBefore")
        return defaults
    }
}
