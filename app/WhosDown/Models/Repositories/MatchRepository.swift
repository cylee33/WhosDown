import FirebaseFirestore
import Foundation

/// Reads and writes `matches/{matchId}`. Each feature adds the methods it needs
/// (1.5 nearby query, 1.8 listener, 1.11 publish, 1.18 edit and cancel, 1.28 transfer).
protocol MatchRepository {
    /// Scheduled Matches that haven't ended, soonest first. Phase 0 placeholder for Discover; 1.5 replaces it with the nearby query.
    func upcomingMatches() async throws -> [Match]
    /// W3 (1.11): the Match, the Host's own approved RSVP, and the Match chat, in one batch. Returns the Match ID.
    func publish(_ draft: MatchDraft, host: UserProfile) async throws -> String
}

final class FirebaseMatchRepository: MatchRepository {
    private let db = Firestore.firestore()

    func publish(_ draft: MatchDraft, host: UserProfile) async throws -> String {
        guard let sport = draft.sport, let venue = draft.venue, let hostId = host.id else { throw PublishError.incomplete }
        let match = db.collection("matches").document()
        let now = FieldValue.serverTimestamp()
        let title = draft.resolvedTitle
        let batch = db.batch()
        batch.setData([
            "title": title,
            "titleLowercase": title.lowercased(),
            "sport": sport.rawValue,
            "customSportName": sport == .other ? (ProfileRules.cleanedCustomSportName(draft.customSportName) as Any) : NSNull(),
            "notes": ProfileRules.trimmedOrNil(draft.notes) ?? NSNull(),
            "hostId": hostId,
            "hostName": host.displayName,
            "venueId": venue.id ?? "",
            "venueName": venue.name,
            "location": ["latitude": venue.location.latitude, "longitude": venue.location.longitude],
            "geohash": Geohash.encode(latitude: venue.location.latitude, longitude: venue.location.longitude),
            "isIndoor": venue.isIndoor,
            "surface": venue.surface,
            "hasLights": venue.hasLights,
            "startTime": Timestamp(date: draft.startTime),
            "endTime": Timestamp(date: draft.endTime),
            "skillLevel": draft.skillLevel.rawValue,
            "joinType": draft.joinType.rawValue,
            "priceCents": draft.priceCents,
            "playerLimit": draft.playerLimit,
            "waitlistEnabled": draft.waitlistEnabled,
            "joinedCount": 1,
            "pendingCount": 0,
            "waitlistCount": 0,
            "waitlistIds": [String](),
            "attendeePreview": [host.initials],
            "fieldReserved": draft.fieldReserved,
            "reservationWindow": draft.fieldReserved ? (ProfileRules.trimmedOrNil(draft.reservationWindow) as Any) : NSNull(),
            "facilityNote": ProfileRules.trimmedOrNil(draft.facilityNote) ?? NSNull(),
            "status": MatchStatus.scheduled.rawValue,
            "cancelReason": NSNull(),
            "checkedInAt": NSNull(),
            "createdAt": now,
            "updatedAt": now,
        ], forDocument: match)
        batch.setData([
            "userId": hostId,
            "displayName": host.displayName,
            "skillLevel": (host.sportLevels[sport.rawValue] ?? .allLevels).rawValue,
            "status": RSVPStatus.approved.rawValue,
            "isHost": true,
            "noteToHost": NSNull(),
            "hostResponse": NSNull(),
            "requestedAt": now,
            "respondedAt": now,
            "checkedIn": false,
            "attended": NSNull(),
        ], forDocument: match.collection("rsvps").document(hostId))
        batch.setData([
            "type": "match",
            "title": title,
            "matchId": match.documentID,
            "lastMessageText": NSNull(),
            "lastMessageAt": NSNull(),
        ], forDocument: db.document("conversations/\(match.documentID)"))
        try await batch.commit()
        return match.documentID
    }

    enum PublishError: Error { case incomplete }

    func upcomingMatches() async throws -> [Match] {
        let snapshot = try await db.collection("matches")
            .whereField("status", isEqualTo: MatchStatus.scheduled.rawValue)
            .getDocuments()
        let now = Date()
        return try snapshot.documents
            .map { try $0.decoded(as: Match.self) }
            .filter { $0.endTime > now }
            .sorted { $0.startTime < $1.startTime }
    }
}
