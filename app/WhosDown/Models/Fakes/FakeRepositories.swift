import Foundation

/// In-memory repositories for SwiftUI previews and view-model tests. No Firebase involved.
final class FakeAuthRepository: AuthRepository {
    var currentUserId: String?
    private var continuations: [AsyncStream<String?>.Continuation] = []

    init(signedInAs userId: String? = "seed_alex") {
        currentUserId = userId
    }

    func authStateChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            continuation.yield(currentUserId)
            continuations.append(continuation)
        }
    }

    func signIn(email: String, password: String) async throws {
        currentUserId = "seed_" + (email.split(separator: "@").first.map(String.init) ?? "player")
        continuations.forEach { $0.yield(currentUserId) }
    }

    func signOut() throws {
        currentUserId = nil
        continuations.forEach { $0.yield(nil) }
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
