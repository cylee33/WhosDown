import Foundation

/// `matches/{matchId}`: one pickup sports session. Host and Venue facts are copied in
/// so lists need one query (architecture §2).
nonisolated struct Match: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var title: String
    var titleLowercase: String
    var sport: Sport
    var customSportName: String?
    var notes: String?
    var hostId: String
    var hostName: String
    var venueId: String
    var venueName: String
    var location: Coordinate
    var geohash: String
    var isIndoor: Bool
    var surface: String
    var hasLights: Bool
    var startTime: Date
    var endTime: Date
    var skillLevel: SkillLevel
    var joinType: JoinType
    var priceCents: Int
    var playerLimit: Int
    var waitlistEnabled: Bool
    var joinedCount: Int
    var pendingCount: Int
    var waitlistCount: Int
    /// The waiting line, in order (ADR-0008).
    var waitlistIds: [String]
    var attendeePreview: [String]
    var fieldReserved: Bool
    var reservationWindow: String?
    var facilityNote: String?
    var status: MatchStatus
    var cancelReason: String?
    var checkedInAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var isFull: Bool { joinedCount >= playerLimit }
    var spotsLeft: Int { max(playerLimit - joinedCount, 0) }
    var sportName: String { sport == .other ? (customSportName ?? Sport.other.displayName) : sport.displayName }
}
