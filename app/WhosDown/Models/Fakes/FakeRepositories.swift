import Foundation

/// In-memory repositories for SwiftUI previews and view-model tests. No Firebase involved.
final class FakeAuthRepository: AuthRepository {
    private(set) var currentUser: AuthUser?
    /// When set, the next call throws it.
    var nextError: AuthError?
    private(set) var calls: [String] = []
    private var continuations: [AsyncStream<AuthUser?>.Continuation] = []

    init(signedInAs userId: String? = "seed_alex", isGuest: Bool = false) {
        currentUser = userId.map { AuthUser(id: $0, isGuest: isGuest) }
    }

    func authStateChanges() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            continuation.yield(currentUser)
            continuations.append(continuation)
        }
    }

    func createAccount(email: String, password: String) async throws -> AuthUser {
        calls.append("createAccount")
        try throwIfNeeded()
        let user = AuthUser(id: "new_" + email, isGuest: false)
        setUser(user)
        return user
    }

    func signIn(email: String, password: String) async throws {
        calls.append("signIn")
        try throwIfNeeded()
        setUser(AuthUser(id: "seed_" + (email.split(separator: "@").first.map(String.init) ?? "player"), isGuest: false))
    }

    func sendPasswordReset(email: String) async throws {
        calls.append("sendPasswordReset")
        try throwIfNeeded()
    }

    func signOut() throws {
        calls.append("signOut")
        setUser(nil)
    }

    func signInAsGuest() async throws {
        calls.append("signInAsGuest")
        try throwIfNeeded()
        setUser(AuthUser(id: "guest_1", isGuest: true))
    }

    func linkGuestAccount(email: String, password: String) async throws -> AuthUser {
        calls.append("linkGuestAccount")
        try throwIfNeeded()
        guard let current = currentUser, current.isGuest else { throw AuthError.unknown }
        let user = AuthUser(id: current.id, isGuest: false)
        setUser(user)
        return user
    }

    private func throwIfNeeded() throws {
        if let error = nextError {
            nextError = nil
            throw error
        }
    }

    private func setUser(_ user: AuthUser?) {
        currentUser = user
        continuations.forEach { $0.yield(user) }
    }
}

final class FakeUserRepository: UserRepository {
    var profiles: [String: UserProfile]
    private(set) var createdProfiles: [(userId: String, displayName: String, email: String)] = []
    private var continuations: [String: [AsyncThrowingStream<UserProfile?, Error>.Continuation]] = [:]

    init(profiles: [String: UserProfile] = ["seed_alex": .sample]) {
        self.profiles = profiles
    }

    func createProfile(userId: String, displayName: String, email: String) async throws {
        createdProfiles.append((userId, displayName, email))
        update(userId, UserProfile(
            id: userId, displayName: displayName, displayNameLowercase: displayName.lowercased(),
            playStyles: [], sportLevels: [:], createdAt: .now
        ))
    }

    func profileChanges(userId: String) -> AsyncThrowingStream<UserProfile?, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(profiles[userId])
            continuations[userId, default: []].append(continuation)
        }
    }

    private(set) var uploadedAvatars: [String: Data] = [:]
    private(set) var savedPrefs: [String: UserSettings.NotificationPrefs] = [:]
    /// When set, the next write throws it.
    var nextError: Error?

    func updateProfile(userId: String, fields: ProfileFields) async throws {
        if let error = nextError { nextError = nil; throw error }
        guard var profile = profiles[userId] else { return }
        profile.displayName = fields.displayName
        profile.displayNameLowercase = fields.displayName.lowercased()
        profile.photoURL = fields.photoURL
        profile.bio = fields.bio
        profile.homeArea = fields.homeArea
        profile.playStyles = fields.playStyles
        profile.sportLevels = fields.sportLevels
        profile.customSportName = fields.customSportName
        update(userId, profile)
    }

    func uploadAvatar(userId: String, jpegData: Data) async throws -> String {
        if let error = nextError { nextError = nil; throw error }
        uploadedAvatars[userId] = jpegData
        return "https://example.test/\(userId)/avatar.jpg"
    }

    func saveNotificationPrefs(userId: String, prefs: UserSettings.NotificationPrefs) async throws {
        if let error = nextError { nextError = nil; throw error }
        savedPrefs[userId] = prefs
    }

    func completeOnboarding(userId: String) async throws {
        if let error = nextError { nextError = nil; throw error }
        guard var profile = profiles[userId] else { return }
        profile.onboardedAt = .now
        update(userId, profile)
    }

    private func update(_ userId: String, _ profile: UserProfile) {
        profiles[userId] = profile
        continuations[userId]?.forEach { $0.yield(profile) }
    }
}

final class FakePermissionsService: PermissionsService {
    var allowLocation = true
    var allowNotifications = true
    private(set) var notificationRequests = 0
    private(set) var locationRequests = 0

    func requestLocation() async -> Bool {
        locationRequests += 1
        return allowLocation
    }

    func requestNotifications() async -> Bool {
        notificationRequests += 1
        return allowNotifications
    }
}

final class FakeMatchRepository: MatchRepository {
    var matches: [Match]
    var error: Error?

    init(matches: [Match] = Match.samples, error: Error? = nil) {
        self.matches = matches
        self.error = error
    }

    func upcomingMatches() async throws -> [Match] {
        if let error { throw error }
        return matches.sorted { $0.startTime < $1.startTime }
    }
}

extension UserProfile {
    static let sample = UserProfile(
        id: "seed_alex", displayName: "Alex Morgan", displayNameLowercase: "alex morgan", photoURL: nil,
        bio: "Midfielder who likes quick passing and friendly competitive Matches.", homeArea: "Oakland / CMU",
        playStyles: [.social, .competitive], sportLevels: ["soccer": .allLevels, "tennis": .casual],
        customSportName: nil, createdAt: .now, onboardedAt: .now
    )
}

extension Match {
    static func sample(
        id: String = "m_sample",
        title: String = "Pickup Soccer",
        startsInHours: Double = 3,
        joinedCount: Int = 12,
        playerLimit: Int = 14,
        joinType: JoinType = .approvalRequired
    ) -> Match {
        let start = Date().addingTimeInterval(startsInHours * 3600)
        return Match(
            id: id, title: title, titleLowercase: title.lowercased(), sport: .soccer, customSportName: nil,
            notes: "Bring a light + dark shirt.", hostId: "seed_jamie", hostName: "Jamie Morales",
            venueId: "v_cmu_soccer", venueName: "CMU Soccer Field",
            location: Coordinate(latitude: 40.4433, longitude: -79.9436), geohash: "dppnhf",
            isIndoor: false, surface: "turf", hasLights: true,
            startTime: start, endTime: start.addingTimeInterval(5400),
            skillLevel: .allLevels, joinType: joinType, priceCents: 0, playerLimit: playerLimit,
            waitlistEnabled: true, joinedCount: joinedCount, pendingCount: 0, waitlistCount: 0, waitlistIds: [],
            attendeePreview: ["JM", "AM"], fieldReserved: false, reservationWindow: nil, facilityNote: nil,
            status: .scheduled, cancelReason: nil, checkedInAt: nil, createdAt: .now, updatedAt: .now
        )
    }

    static let samples: [Match] = [
        .sample(id: "m1", title: "Pickup Soccer", startsInHours: 3),
        .sample(id: "m2", title: "7v7 at Schenley", startsInHours: 5, joinedCount: 4, playerLimit: 4, joinType: .open),
        .sample(id: "m3", title: "Beginner Kickabout", startsInHours: 26, joinedCount: 2, playerLimit: 10, joinType: .open),
    ]
}
