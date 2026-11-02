import Foundation

/// H36 own profile and H10 another Player's profile (1.22). The own profile comes live from `Session`;
/// another Player's is read once.
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile?
    private(set) var reliability: Reliability?
    private(set) var errorMessage: String?

    let userId: String
    private let users: UserRepository
    private let reliabilityRepository: ReliabilityRepository
    private let auth: AuthRepository

    init(userId: String, profile: UserProfile? = nil, users: UserRepository, reliability: ReliabilityRepository, auth: AuthRepository) {
        self.userId = userId
        self.profile = profile
        self.users = users
        self.reliabilityRepository = reliability
        self.auth = auth
    }

    var sportRows: [(sport: String, level: String)] { profile.map(ProfileRules.sportRows) ?? [] }
    var subtitle: String { profile.map(ProfileRules.subtitle) ?? "" }

    /// "17 / 18 checked-in Matches attended", or nil for a new player.
    var attendanceLine: String? {
        guard let reliability, reliability.checkedIn > 0 else { return nil }
        return "\(reliability.attended) / \(reliability.checkedIn) checked-in Matches attended"
    }

    /// "34 Matches played" (1.22 rule 3).
    var matchesPlayedLine: String? {
        reliability.map { "\($0.attended) \($0.attended == 1 ? "Match" : "Matches") played" }
    }

    /// Keeps the own profile in step with `Session`'s live copy.
    func update(_ profile: UserProfile?) {
        self.profile = profile
    }

    /// Loads Reliability, and the profile too when it wasn't handed in (H10).
    func load() async {
        do {
            if profile == nil {
                profile = try await users.profile(userId: userId)
                if profile == nil { errorMessage = "This Player's profile isn't available." }
            }
            reliability = try await reliabilityRepository.reliability(userId: userId)
        } catch {
            errorMessage = "Couldn't load this profile. Check your connection and try again."
        }
    }

    func signOut() {
        try? auth.signOut()
    }
}
