import Foundation
import Testing
@testable import WhosDown

/// 1.22 Profile.
struct ReliabilityTests {
    @Test func percentAndLabel() {
        #expect(Reliability(checkedIn: 18, attended: 17).percent == 94)
        #expect(Reliability(checkedIn: 18, attended: 17).label == "94% reliable")
        #expect(Reliability(checkedIn: 3, attended: 0).label == "0% reliable")
        #expect(Reliability(checkedIn: 0, attended: 0).percent == nil)
        #expect(Reliability(checkedIn: 0, attended: 0).label == "New player")
    }

    @Test func sportRowsAndSubtitleFollowSportOrder() {
        var profile = UserProfile.sample
        profile.sportLevels = ["tennis": .casual, "other": .competitive, "soccer": .allLevels]
        profile.customSportName = "Spikeball"
        profile.playStyles = [.competitive, .social]
        #expect(ProfileRules.sportRows(profile).map(\.sport) == ["Soccer", "Tennis", "Spikeball"])
        #expect(ProfileRules.sportRows(profile).map(\.level) == ["All Levels", "Casual", "Competitive"])
        #expect(ProfileRules.subtitle(profile) == "Soccer · Tennis · Spikeball · Social / casual · Competitive")
    }
}

@MainActor
struct ProfileViewModelTests {
    @Test func otherPlayersProfileLoadsWithReliability() async {
        let viewModel = ProfileViewModel(
            userId: "seed_alex", users: FakeUserRepository(), reliability: FakeReliabilityRepository(), auth: FakeAuthRepository()
        )
        await viewModel.load()
        #expect(viewModel.profile?.displayName == "Alex Morgan")
        #expect(viewModel.reliability?.percent == 94)
        #expect(viewModel.attendanceLine == "17 / 18 checked-in Matches attended")
        #expect(viewModel.matchesPlayedLine == "17 Matches played")
    }

    @Test func newPlayerHasNoAttendanceLine() async {
        let viewModel = ProfileViewModel(
            userId: "seed_alex", users: FakeUserRepository(), reliability: FakeReliabilityRepository(records: [:]), auth: FakeAuthRepository()
        )
        await viewModel.load()
        #expect(viewModel.reliability?.label == "New player")
        #expect(viewModel.attendanceLine == nil)
    }

    @Test func missingProfileSaysSo() async {
        let viewModel = ProfileViewModel(
            userId: "nobody", users: FakeUserRepository(), reliability: FakeReliabilityRepository(), auth: FakeAuthRepository()
        )
        await viewModel.load()
        #expect(viewModel.errorMessage == "This Player's profile isn't available.")
    }

    @Test func signOutSignsOut() {
        let auth = FakeAuthRepository()
        let viewModel = ProfileViewModel(userId: "seed_alex", users: FakeUserRepository(), reliability: FakeReliabilityRepository(), auth: auth)
        viewModel.signOut()
        #expect(auth.currentUser == nil)
    }
}

@MainActor
struct EditProfileViewModelTests {
    private let users = FakeUserRepository()

    private func makeViewModel() -> EditProfileViewModel {
        EditProfileViewModel(userId: "seed_alex", profile: users.profiles["seed_alex"]!, users: users)
    }

    @Test func saveIsDisabledUntilSomethingChanges() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canSave)
        viewModel.homeArea = "Squirrel Hill"
        #expect(viewModel.canSave)
        viewModel.homeArea = "Oakland / CMU"
        #expect(!viewModel.canSave)
    }

    @Test func invalidInputBlocksSave() {
        let viewModel = makeViewModel()
        viewModel.displayName = "   "
        #expect(viewModel.nameError != nil)
        #expect(!viewModel.canSave)
        viewModel.displayName = "Alex"
        viewModel.bio = String(repeating: "x", count: 301)
        #expect(!viewModel.canSave)
    }

    @Test func removingEverySportIsNotAllowed() {
        let viewModel = makeViewModel()
        viewModel.selectedSports = []
        #expect(!viewModel.canContinueFromSports)
        #expect(!viewModel.canSave)
    }

    @Test func savesEditedFieldsAndSports() async {
        let viewModel = makeViewModel()
        viewModel.displayName = " Alex M. "
        viewModel.bio = ""
        viewModel.selectedSports.append(.basketball)
        viewModel.continueFromSports()
        viewModel.levels[.basketball] = .competitive
        #expect(await viewModel.save())
        let saved = users.profiles["seed_alex"]
        #expect(saved?.displayName == "Alex M.")
        #expect(saved?.displayNameLowercase == "alex m.")
        #expect(saved?.bio == nil)
        #expect(saved?.sportLevels == ["soccer": .allLevels, "tennis": .casual, "basketball": .competitive])
    }

    @Test func saveFailureShowsAMessage() async {
        let viewModel = makeViewModel()
        viewModel.homeArea = "Squirrel Hill"
        users.nextError = URLError(.notConnectedToInternet)
        #expect(await !viewModel.save())
        #expect(viewModel.errorMessage == "Couldn't save. Check your connection and try again.")
    }
}
