import Foundation
import Testing
import UIKit
@testable import WhosDown

/// Runs the real Firebase repositories against the local emulator (the Debug test host is already
/// configured for it by `FirebaseSetup`). Skipped when the emulator isn't running:
/// start it with `npm run emulators` in `firebase/`.
private let emulatorIsRunning: Bool = {
    (try? Data(contentsOf: URL(string: "http://\(FirebaseSetup.emulatorHost):9099")!)) != nil
}()

@MainActor
@Suite(.serialized, .enabled(if: emulatorIsRunning, "Firebase emulator not running"))
struct EmulatorIntegrationTests {
    let auth = FirebaseAuthRepository()
    let users = FirebaseUserRepository()

    private func uniqueEmail() -> String {
        "test-\(UUID().uuidString.prefix(8).lowercased())@whosdown.test"
    }

    @Test func createAccountWritesProfileAndSignsIn() async throws {
        let email = uniqueEmail()
        let user = try await auth.createAccount(email: email, password: "whosdown123")
        defer { try? auth.signOut() }
        #expect(auth.currentUser == user)
        #expect(!user.isGuest)

        try await users.createProfile(userId: user.id, displayName: "Integration Test", email: email)

        var profile: UserProfile?
        for try await value in users.profileChanges(userId: user.id) {
            if let value { profile = value; break }
        }
        #expect(profile?.id == user.id)
        #expect(profile?.displayName == "Integration Test")
        #expect(profile?.displayNameLowercase == "integration test")
        #expect(profile?.onboardedAt == nil)

        try await users.completeOnboarding(userId: user.id)
        for try await value in users.profileChanges(userId: user.id) where value?.onboardedAt != nil {
            break
        }
    }

    @Test func usedEmailAndWrongPasswordGivePlainErrors() async throws {
        let email = uniqueEmail()
        _ = try await auth.createAccount(email: email, password: "whosdown123")
        try auth.signOut()

        await #expect(throws: AuthError.emailInUse) {
            _ = try await auth.createAccount(email: email, password: "whosdown123")
        }
        await #expect(throws: AuthError.wrongCredentials) {
            try await auth.signIn(email: email, password: "not-the-password")
        }
        try await auth.signIn(email: email, password: "whosdown123")
        #expect(auth.currentUser != nil)
        try auth.signOut()
        #expect(auth.currentUser == nil)
    }

    @Test func guestUpgradeKeepsTheIdAndCanWriteItsProfile() async throws {
        try await auth.signInAsGuest()
        defer { try? auth.signOut() }
        let guest = try #require(auth.currentUser)
        #expect(guest.isGuest)

        let email = uniqueEmail()
        let upgraded = try await auth.linkGuestAccount(email: email, password: "whosdown123")
        #expect(upgraded.id == guest.id)
        #expect(!upgraded.isGuest)
        // Succeeds only if the refreshed token no longer says "anonymous" (security rules, 1.3).
        try await users.createProfile(userId: upgraded.id, displayName: "Former Guest", email: email)
    }

    @Test func onboardingSavesProfilePhotoAndPreferences() async throws {
        let email = uniqueEmail()
        let user = try await auth.createAccount(email: email, password: "whosdown123")
        defer { try? auth.signOut() }
        try await users.createProfile(userId: user.id, displayName: "Onboarding Test", email: email)
        var profile: UserProfile?
        for try await value in users.profileChanges(userId: user.id) {
            if let value { profile = value; break }
        }
        var fields = ProfileFields(try #require(profile))

        let png = try #require(UIImage(systemName: "star")?.pngData())
        let jpeg = try #require(AvatarImage.jpegData(from: png))
        fields.photoURL = try await users.uploadAvatar(userId: user.id, jpegData: jpeg)
        fields.sportLevels = ["soccer": .intermediate, "other": .casual]
        fields.customSportName = "Spikeball"
        fields.playStyles = [.social]
        fields.bio = "Midfielder."
        fields.homeArea = "Oakland / CMU"
        try await users.updateProfile(userId: user.id, fields: fields)
        try await users.saveNotificationPrefs(
            userId: user.id,
            prefs: .init(approvals: true, timeOrLocationChanges: false, cancellations: true)
        )
        try await users.completeOnboarding(userId: user.id)

        for try await value in users.profileChanges(userId: user.id) where value?.onboardedAt != nil {
            #expect(value?.sportLevels == ["soccer": .intermediate, "other": .casual])
            #expect(value?.customSportName == "Spikeball")
            #expect(value?.photoURL?.contains("avatar.jpg") == true)
            break
        }
    }

    @Test func passwordResetForUnknownEmailDoesNotThrowANetworkError() async {
        do {
            try await auth.sendPasswordReset(email: uniqueEmail())
        } catch let error as AuthError {
            #expect(error != .network)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }
}
