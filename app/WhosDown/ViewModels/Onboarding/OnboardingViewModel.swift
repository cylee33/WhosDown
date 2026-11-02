import Foundation

/// Onboarding flow state (1.4). Phase 1 step 1 (1.2) only needs `finish()`; 1.4 adds the steps.
@Observable
final class OnboardingViewModel {
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    private let userId: String
    private let users: UserRepository

    init(userId: String, users: UserRepository) {
        self.userId = userId
        self.users = users
    }

    /// H44 "Find Matches": sets `onboardedAt`; Session then closes onboarding.
    func finish() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await users.completeOnboarding(userId: userId)
        } catch {
            errorMessage = "Couldn't save. Check your connection and try again."
        }
    }
}
