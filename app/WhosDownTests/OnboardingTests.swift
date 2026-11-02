import Foundation
import Testing
import UIKit
@testable import WhosDown

/// 1.4 Onboarding.
@MainActor
struct OnboardingTests {
    private let userId = "new_alex"
    private let users: FakeUserRepository
    private let permissions = FakePermissionsService()
    private let progress: UserDefaults

    init() {
        users = FakeUserRepository(profiles: ["new_alex": UserProfile(
            id: "new_alex", displayName: "Alex Morgan", displayNameLowercase: "alex morgan",
            playStyles: [], sportLevels: [:], createdAt: .now
        )])
        progress = UserDefaults(suiteName: "OnboardingTests-\(UUID().uuidString)")!
    }

    private func makeViewModel() -> OnboardingViewModel {
        OnboardingViewModel(userId: userId, profile: users.profiles[userId], users: users, permissions: permissions, progress: progress)
    }

    @Test func needsAtLeastOneSportAndANameForOther() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canContinueFromSports)
        viewModel.selectedSports = [.soccer]
        #expect(viewModel.canContinueFromSports)
        viewModel.selectedSports = [.soccer, .other]
        #expect(!viewModel.canContinueFromSports)
        viewModel.customSportName = "Spikeball"
        #expect(viewModel.canContinueFromSports)
        viewModel.customSportName = String(repeating: "x", count: 31)
        #expect(!viewModel.canContinueFromSports)
    }

    @Test func everyChosenSportStartsAtAllLevels() {
        let viewModel = makeViewModel()
        viewModel.selectedSports = [.soccer, .tennis]
        viewModel.continueFromSports()
        #expect(viewModel.levels == [.soccer: .allLevels, .tennis: .allLevels])
        #expect(viewModel.currentStep == .levels)
    }

    @Test func fullFlowSavesEachStepAndFinishes() async throws {
        let viewModel = makeViewModel()
        viewModel.selectedSports = [.soccer, .other]
        viewModel.customSportName = " Spikeball "
        viewModel.continueFromSports()
        viewModel.levels[.soccer] = .intermediate
        await viewModel.continueFromLevels()
        #expect(users.profiles[userId]?.sportLevels == ["soccer": .intermediate, "other": .allLevels])
        #expect(users.profiles[userId]?.customSportName == "Spikeball")
        #expect(viewModel.currentStep == .profile)

        viewModel.playStyles = [.competitive, .social]
        viewModel.bio = "  Midfielder.  "
        viewModel.homeArea = ""
        viewModel.pickedPhotoData = try #require(UIImage(systemName: "star")?.pngData())
        await viewModel.continueFromProfile()
        let profile = try #require(users.profiles[userId])
        #expect(profile.playStyles == [.social, .competitive])
        #expect(profile.bio == "Midfielder.")
        #expect(profile.homeArea == nil)
        #expect(profile.photoURL != nil)
        let avatar = try #require(users.uploadedAvatars[userId].flatMap(UIImage.init(data:)))
        #expect(avatar.size == CGSize(width: 512, height: 512))
        #expect(viewModel.currentStep == .permissions)

        viewModel.prefs.timeOrLocationChanges = false
        await viewModel.continueFromPermissions()
        #expect(users.savedPrefs[userId]?.timeOrLocationChanges == false)
        #expect(permissions.notificationRequests == 1)
        #expect(viewModel.currentStep == .done)

        await viewModel.finish()
        #expect(users.profiles[userId]?.onboardedAt != nil)
    }

    @Test func deniedNotificationsDoNotBlockOnboarding() async {
        permissions.allowNotifications = false
        let viewModel = makeViewModel()
        viewModel.path = [.levels, .profile, .permissions]
        await viewModel.continueFromPermissions()
        #expect(viewModel.currentStep == .done)
    }

    @Test func overLongBioBlocksFinishSetup() async {
        let viewModel = makeViewModel()
        viewModel.path = [.levels, .profile]
        viewModel.bio = String(repeating: "x", count: 301)
        #expect(viewModel.bioError != nil)
        await viewModel.continueFromProfile()
        #expect(viewModel.currentStep == .profile)
    }

    @Test func resumesAtTheFirstUnfinishedStepWithEarlierAnswers() async {
        let first = makeViewModel()
        first.selectedSports = [.tennis]
        first.continueFromSports()
        first.levels[.tennis] = .casual
        await first.continueFromLevels()
        #expect(first.currentStep == .profile)

        // The app is closed and reopened.
        let reopened = makeViewModel()
        #expect(reopened.currentStep == .profile)
        #expect(reopened.selectedSports == [.tennis])
        #expect(reopened.levels == [.tennis: .casual])
    }

    @Test func saveFailureStaysOnTheStepWithAMessage() async {
        let viewModel = makeViewModel()
        viewModel.selectedSports = [.soccer]
        viewModel.continueFromSports()
        users.nextError = URLError(.notConnectedToInternet)
        await viewModel.continueFromLevels()
        #expect(viewModel.currentStep == .levels)
        #expect(viewModel.errorMessage == "Couldn't save. Check your connection and try again.")
    }
}
