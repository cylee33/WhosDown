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

    func profile(userId: String) async throws -> UserProfile? {
        profiles[userId]
    }

    var savedRadius: [String: Double] = [:]

    func settings(userId: String) async throws -> UserSettings? {
        UserSettings(
            email: "\(userId)@whosdown.test",
            notificationPrefs: .init(approvals: true, timeOrLocationChanges: true, cancellations: true),
            searchRadiusMiles: savedRadius[userId] ?? 3
        )
    }

    func saveSearchRadius(userId: String, miles: Double) async throws {
        savedRadius[userId] = miles
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

final class FakeReliabilityRepository: ReliabilityRepository {
    var records: [String: Reliability]

    init(records: [String: Reliability] = ["seed_alex": Reliability(checkedIn: 18, attended: 17)]) {
        self.records = records
    }

    func reliability(userId: String) async throws -> Reliability {
        records[userId] ?? Reliability(checkedIn: 0, attended: 0)
    }
}

final class FakeVenueRepository: VenueRepository {
    var venues: [Venue]
    private(set) var created: [Venue] = []
    var nextError: Error?

    init(venues: [Venue] = Venue.samples) {
        self.venues = venues
    }

    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Venue] {
        if let error = nextError { nextError = nil; throw error }
        return VenueRules.sortedByDistance(venues, from: center, within: radiusMeters)
    }

    func search(namePrefix: String) async throws -> [Venue] {
        if let error = nextError { nextError = nil; throw error }
        let prefix = namePrefix.lowercased()
        return venues.filter { $0.nameLowercase.hasPrefix(prefix) }
    }

    func create(_ draft: VenueDraft, createdBy userId: String) async throws -> Venue {
        if let error = nextError { nextError = nil; throw error }
        let venue = Venue(
            id: "v_new_\(created.count + 1)", name: draft.name, nameLowercase: draft.name.lowercased(), address: draft.address,
            location: draft.location, geohash: Geohash.encode(latitude: draft.location.latitude, longitude: draft.location.longitude),
            isIndoor: draft.isIndoor, surface: draft.surface.rawValue, hasLights: draft.hasLights, sports: [], createdBy: userId
        )
        created.append(venue)
        venues.append(venue)
        return venue
    }
}

final class FakePlaceSearchService: PlaceSearchService {
    var places: [Place]
    var nextError: Error?

    init(places: [Place] = [
        Place(name: "Schenley Oval Sports Complex", address: "Schenley Dr, Pittsburgh", location: Coordinate(latitude: 40.43642, longitude: -79.94538)),
        Place(name: "Schenley Park Tennis Courts", address: "Overlook Dr, Pittsburgh", location: Coordinate(latitude: 40.4317, longitude: -79.9440)),
    ]) {
        self.places = places
    }

    func search(_ text: String, near center: Coordinate) async throws -> [Place] {
        if let error = nextError { nextError = nil; throw error }
        return places.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }
}

final class FakeLocationService: LocationService {
    var location: Coordinate?
    init(location: Coordinate? = .cmu) { self.location = location }
    func currentLocation() async -> Coordinate? { location }
}

extension Venue {
    static func sample(_ id: String, _ name: String, _ latitude: Double, _ longitude: Double, indoor: Bool = false, surface: String = "turf", lights: Bool = true) -> Venue {
        Venue(
            id: id, name: name, nameLowercase: name.lowercased(), address: "Pittsburgh, PA",
            location: Coordinate(latitude: latitude, longitude: longitude),
            geohash: Geohash.encode(latitude: latitude, longitude: longitude),
            isIndoor: indoor, surface: surface, hasLights: lights, sports: [], createdBy: "seed_jamie"
        )
    }

    static let samples: [Venue] = [
        .sample("v_cmu_soccer", "CMU Soccer Field", 40.4433, -79.9436),
        .sample("v_schenley_oval", "Schenley Oval", 40.4364, -79.9454, surface: "grass", lights: false),
        .sample("v_cmu_gym", "CMU Wiegand Gym", 40.4436, -79.9424, indoor: true, surface: "hardwood"),
    ]
}

final class FakeWeatherService: WeatherService {
    var summary: WeatherSummary? = WeatherSummary(temperatureF: 64, condition: "Clear", rainChance: 8)
    func forecast(at location: Coordinate, for date: Date) async -> WeatherSummary? { summary }
}

final class FakeRSVPRepository: RSVPRepository {
    var approved: [String: [RSVP]]
    var myApproved: [String: [String]]
    var mine: [String: RSVP]
    var pending: [String: [RSVP]]

    init(
        approved: [String: [RSVP]] = ["m1": RSVP.samples],
        myApproved: [String: [String]] = ["seed_alex": ["m1"]],
        mine: [String: RSVP] = [:],
        pending: [String: [RSVP]] = [:]
    ) {
        self.approved = approved
        self.myApproved = myApproved
        self.mine = mine
        self.pending = pending
    }

    /// Yields the current roster once, then ends (real listeners stay open).
    func approvedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(RosterRules.ordered(approved[matchId] ?? []))
            continuation.finish()
        }
    }

    func myApprovedMatchIds(userId: String) async throws -> [String] {
        myApproved[userId] ?? []
    }

    func myRSVPChanges(matchId: String, userId: String) -> AsyncThrowingStream<RSVP?, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(mine[matchId])
            continuation.finish()
        }
    }

    func pendingChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(pending[matchId] ?? [])
            continuation.finish()
        }
    }

    func joinOpen(matchId: String, player: UserProfile, sport: Sport) async throws {}
    func requestToJoin(matchId: String, player: UserProfile, sport: Sport, note: String?) async throws {}
    func approve(matchId: String, userId: String, hostId: String) async throws {}
    func decline(matchId: String, userId: String, hostId: String, message: String?) async throws {}
    func leave(matchId: String, userId: String) async throws {}
}

final class FakeNotificationRepository: NotificationRepository {
    func send(
        to userId: String, type: NotificationType, title: String, body: String,
        matchId: String, fromUserId: String, hostNote: String?
    ) async throws {}
}

final class FakeChatRepository: ChatRepository {
    func conversationChanges(matchId: String) -> AsyncThrowingStream<Conversation?, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        }
    }
}

extension RSVP {
    static func sample(_ userId: String, _ name: String, host: Bool = false, level: SkillLevel = .allLevels, minutesAgo: Double) -> RSVP {
        let time = Date.now.addingTimeInterval(-minutesAgo * 60)
        return RSVP(
            id: userId, userId: userId, displayName: name, skillLevel: level, status: .approved, isHost: host,
            noteToHost: nil, hostResponse: nil, requestedAt: time, respondedAt: time, checkedIn: false, attended: nil
        )
    }

    static let samples: [RSVP] = [
        .sample("seed_mina", "Mina Kim", level: .intermediate, minutesAgo: 30),
        .sample("seed_alex", "Alex Morgan", minutesAgo: 60),
        .sample("seed_jamie", "Jamie Morales", host: true, level: .intermediate, minutesAgo: 120),
    ]
}

final class FakeMatchRepository: MatchRepository {
    var matches: [Match]
    var error: Error?

    init(matches: [Match] = Match.samples, error: Error? = nil) {
        self.matches = matches
        self.error = error
    }

    private(set) var published: [(draft: MatchDraft, hostId: String)] = []

    func publish(_ draft: MatchDraft, host: UserProfile) async throws -> String {
        if let error { throw error }
        published.append((draft, host.id ?? ""))
        return "m_published_\(published.count)"
    }

    func upcomingMatches() async throws -> [Match] {
        if let error { throw error }
        return matches.sorted { $0.startTime < $1.startTime }
    }

    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Match] {
        if let error { throw error }
        return matches
            .filter { $0.status == .scheduled && $0.endTime > .now && VenueRules.distanceMeters($0.location, center) <= radiusMeters }
            .sorted { VenueRules.distanceMeters($0.location, center) < VenueRules.distanceMeters($1.location, center) }
    }

    /// Yields the current value once, then ends (real listeners stay open).
    func matchChanges(matchId: String) -> AsyncThrowingStream<Match?, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(matches.first { $0.id == matchId })
            continuation.finish()
        }
    }

    func matches(ids: [String]) async throws -> [Match] {
        if let error { throw error }
        return matches.filter { ids.contains($0.id ?? "") }
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
