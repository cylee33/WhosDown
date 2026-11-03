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

    /// Uses the seeded past Match "Sunday 7v7", checked in with Alex attended and Mina not (firebase/seed).
    @Test func reliabilityIsCountedFromCheckedInRSVPs() async throws {
        try await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        defer { try? auth.signOut() }
        let reliability = FirebaseReliabilityRepository()
        #expect(try await reliability.reliability(userId: "seed_alex") == Reliability(checkedIn: 1, attended: 1))
        #expect(try await reliability.reliability(userId: "seed_mina") == Reliability(checkedIn: 1, attended: 0))
        #expect(try await reliability.reliability(userId: "seed_sam").label == "New player")
        #expect(try await users.profile(userId: "seed_jamie")?.displayName == "Jamie Morales")
    }

    @Test func venuesNearbySearchAndCreate() async throws {
        try await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        defer { try? auth.signOut() }
        let venues = FirebaseVenueRepository()
        let nearby = try await venues.nearby(center: .cmu, radiusMeters: VenueRules.suggestionRadiusMeters)
        #expect(nearby.first?.name == "CMU Soccer Field")
        #expect(Set(nearby.map(\.name)).isSuperset(of: ["Schenley Oval", "Gesling Stadium", "CMU Wiegand Gym", "CMU Tennis Courts"]))
        #expect(try await venues.search(namePrefix: "schen").map(\.name) == ["Schenley Oval"])

        let name = "Test Field \(UUID().uuidString.prefix(6))"
        let created = try await venues.create(
            VenueDraft(name: name, address: "Pittsburgh", location: Coordinate(latitude: 40.4342, longitude: -79.9058),
                       isIndoor: false, surface: .grass, hasLights: false),
            createdBy: "seed_alex"
        )
        #expect(created.id != nil)
        #expect(try await venues.search(namePrefix: name.lowercased()).first?.id == created.id)
    }

    @Test func publishedMatchShowsUpWithItsHostRSVP() async throws {
        try await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        defer { try? auth.signOut() }
        let host = try #require(try await users.profile(userId: "seed_alex"))
        let venue = try #require(try await FirebaseVenueRepository().search(namePrefix: "cmu soccer").first)
        var draft = MatchDraft()
        draft.sport = .soccer
        draft.title = "Integration Kickabout \(UUID().uuidString.prefix(4))"
        draft.venue = venue
        draft.playerLimit = 12
        draft.joinType = .approvalRequired

        let matches = FirebaseMatchRepository()
        let id = try await matches.publish(draft, host: host)
        let published = try #require(try await matches.upcomingMatches().first { $0.id == id })
        #expect(published.title == draft.title)
        #expect(published.hostId == "seed_alex")
        #expect(published.joinedCount == 1)
        #expect(published.attendeePreview == ["AM"])
        #expect(published.geohash.hasPrefix("dppnhf"))
        #expect(published.venueName == "CMU Soccer Field")
    }

    @Test func discoverQueriesAgainstSeededData() async throws {
        try await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        defer { try? auth.signOut() }
        let matches = FirebaseMatchRepository()
        let nearby = try await matches.nearby(center: .cmu, radiusMeters: 3 * 1609.344)
        let titles = Set(nearby.map(\.title))
        #expect(titles.isSuperset(of: ["Pickup Soccer", "7v7 at Schenley", "Basketball Run"]))
        #expect(!titles.contains("Sunday 7v7"))            // ended
        #expect(!titles.contains("Spikeball on the Cut"))  // cancelled

        let rsvps = FirebaseRSVPRepository()
        let mine = try await rsvps.myApprovedMatchIds(userId: "seed_alex")
        #expect(Set(mine).isSuperset(of: ["m_soccer_tonight", "m_7v7_full"]))
        #expect(try await matches.matches(ids: ["m_soccer_tonight", "m_hoops"]).count == 2)

        var roster: [RSVP] = []
        for try await value in rsvps.approvedChanges(matchId: "m_soccer_tonight") { roster = value; break }
        #expect(roster.first?.displayName == "Jamie Morales")
        #expect(roster.count == 3)

        var live: Match?
        for try await value in matches.matchChanges(matchId: "m_soccer_tonight") { live = value; break }
        #expect(live?.pendingCount == 1)

        let radius = try #require(try await users.settings(userId: "seed_alex"))
        try await users.saveSearchRadius(userId: "seed_alex", miles: radius.searchRadiusMiles)
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
