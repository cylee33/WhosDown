import Foundation

/// `matches/{matchId}/rsvps/{userId}`: a Player's record for one Match, in any status.
/// Document ID = user ID, so a Player has at most one RSVP per Match.
nonisolated struct RSVP: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var userId: String
    var displayName: String
    var skillLevel: SkillLevel
    var status: RSVPStatus
    var isHost: Bool
    var noteToHost: String?
    var hostResponse: String?
    var requestedAt: Date
    var respondedAt: Date?
    /// Set by the Host's Check-in (1.27); Reliability is counted from these (D37).
    var checkedIn: Bool
    var attended: Bool?
}
