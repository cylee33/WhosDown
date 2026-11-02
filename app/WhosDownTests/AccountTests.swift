import Foundation
import Testing
@testable import WhosDown

/// 1.2 Account and sign-in.
struct AccountRulesTests {
    @Test(arguments: ["alex@cmu.edu", "a.b@whosdown.test", "  alex@cmu.edu "])
    func acceptsEmails(_ email: String) {
        #expect(AccountRules.isValidEmail(email))
    }

    @Test(arguments: ["", "alex", "alex@", "@cmu.edu", "alex@cmu", "alex@.edu", "a@b@c.com"])
    func rejectsEmails(_ email: String) {
        #expect(!AccountRules.isValidEmail(email))
    }

    @Test func passwordNeedsEightCharacters() {
        #expect(!AccountRules.isValidPassword("1234567"))
        #expect(AccountRules.isValidPassword("12345678"))
    }

    @Test func displayNameIsTrimmedAndLimited() {
        #expect(AccountRules.cleanedDisplayName("  Alex Morgan ") == "Alex Morgan")
        #expect(AccountRules.cleanedDisplayName("   ") == nil)
        #expect(AccountRules.cleanedDisplayName(String(repeating: "x", count: 40)) != nil)
        #expect(AccountRules.cleanedDisplayName(String(repeating: "x", count: 41)) == nil)
    }
}

@MainActor
struct CreateAccountViewModelTests {
    @Test func createsAccountThenProfile() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        let users = FakeUserRepository(profiles: [:])
        let viewModel = CreateAccountViewModel(auth: auth, users: users)
        viewModel.email = " alex@cmu.edu "
        viewModel.password = "whosdown123"
        viewModel.displayName = " Alex Morgan "
        await viewModel.createAccount()

        #expect(auth.calls == ["createAccount"])
        #expect(users.createdProfiles.count == 1)
        #expect(users.createdProfiles.first?.displayName == "Alex Morgan")
        #expect(users.createdProfiles.first?.email == "alex@cmu.edu")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func invalidInputShowsFieldErrorsAndCallsNothing() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        let viewModel = CreateAccountViewModel(auth: auth, users: FakeUserRepository())
        viewModel.email = "alex"
        viewModel.password = "short"
        viewModel.displayName = ""
        await viewModel.createAccount()

        #expect(auth.calls.isEmpty)
        #expect(viewModel.emailError != nil)
        #expect(viewModel.passwordError != nil)
        #expect(viewModel.nameError != nil)
    }

    @Test func emailInUseShowsPlainSentence() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        auth.nextError = .emailInUse
        let users = FakeUserRepository(profiles: [:])
        let viewModel = CreateAccountViewModel(auth: auth, users: users)
        viewModel.email = "alex@cmu.edu"
        viewModel.password = "whosdown123"
        viewModel.displayName = "Alex"
        await viewModel.createAccount()

        #expect(viewModel.errorMessage == "That email is already in use. Sign in instead?")
        #expect(users.createdProfiles.isEmpty)
        #expect(!viewModel.isWorking)
    }
}

@MainActor
struct SignInViewModelTests {
    @Test func wrongPasswordShowsPlainSentence() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        auth.nextError = .wrongCredentials
        let viewModel = SignInViewModel(auth: auth)
        viewModel.email = "alex@cmu.edu"
        viewModel.password = "nope"
        await viewModel.signIn()
        #expect(viewModel.errorMessage == "Wrong email or password.")
    }

    @Test func resetGivesSameAnswerWhetherOrNotAccountExists() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        let viewModel = SignInViewModel(auth: auth)
        viewModel.email = "alex@cmu.edu"
        await viewModel.sendPasswordReset()
        #expect(viewModel.resetMessage == SignInViewModel.resetSentMessage)

        auth.nextError = .wrongCredentials
        await viewModel.sendPasswordReset()
        #expect(viewModel.resetMessage == SignInViewModel.resetSentMessage)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func resetOfflineSaysSo() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        auth.nextError = .network
        let viewModel = SignInViewModel(auth: auth)
        viewModel.email = "alex@cmu.edu"
        await viewModel.sendPasswordReset()
        #expect(viewModel.errorMessage == "No internet connection.")
    }
}

@MainActor
struct SessionTests {
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test func signedOutThenNewAccountNeedsOnboarding() async {
        let auth = FakeAuthRepository(signedInAs: nil)
        let users = FakeUserRepository(profiles: [:])
        let session = Session(auth: auth, users: users)
        let task = Task { await session.start() }
        defer { task.cancel() }
        await settle()
        #expect(session.state == .signedOut)

        let user = try? await auth.createAccount(email: "alex@cmu.edu", password: "whosdown123")
        try? await users.createProfile(userId: user!.id, displayName: "Alex", email: "alex@cmu.edu")
        await settle()
        #expect(session.state == .active)
        #expect(session.needsOnboarding)

        try? await users.completeOnboarding(userId: user!.id)
        await settle()
        #expect(!session.needsOnboarding)
    }

    @Test func signOutClearsTheProfile() async {
        let auth = FakeAuthRepository(signedInAs: "seed_alex")
        let session = Session(auth: auth, users: FakeUserRepository())
        let task = Task { await session.start() }
        defer { task.cancel() }
        await settle()
        #expect(session.profile?.displayName == "Alex Morgan")

        try? auth.signOut()
        await settle()
        #expect(session.state == .signedOut)
        #expect(session.profile == nil)
    }
}
