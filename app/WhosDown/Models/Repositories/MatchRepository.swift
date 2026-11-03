import FirebaseFirestore
import Foundation

/// Reads and writes `matches/{matchId}`. Each feature adds the methods it needs
/// (1.18 edit and cancel, 1.28 transfer).
protocol MatchRepository {
    /// Scheduled Matches that haven't ended, soonest first (all of them; used by tests and as a fallback).
    func upcomingMatches() async throws -> [Match]
    /// R1 (1.5): scheduled Matches within the radius that haven't ended, nearest first (geohash ranges, then exact distance).
    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Match]
    /// R2 (1.8): one Match, live. Yields nil if it's deleted.
    func matchChanges(matchId: String) -> AsyncThrowingStream<Match?, Error>
    /// Matches by ID (1.5 "Next up", 1.19), in batches of 30.
    func matches(ids: [String]) async throws -> [Match]
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

    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Match] {
        let bounds = Geohash.queryBounds(latitude: center.latitude, longitude: center.longitude, radius: radiusMeters)
        var found: [String: Match] = [:]
        try await withThrowingTaskGroup(of: [Match].self) { group in
            for bound in bounds {
                group.addTask { [db] in
                    let snapshot = try await db.collection("matches")
                        .whereField("status", isEqualTo: MatchStatus.scheduled.rawValue)
                        .order(by: "geohash")
                        .start(at: [bound.start])
                        .end(at: [bound.end])
                        .getDocuments()
                    return try snapshot.documents.map { try $0.decoded(as: Match.self) }
                }
            }
            for try await batch in group {
                for match in batch { if let id = match.id { found[id] = match } }
            }
        }
        let now = Date.now
        return found.values
            .filter { $0.endTime > now && VenueRules.distanceMeters($0.location, center) <= radiusMeters }
            .sorted { VenueRules.distanceMeters($0.location, center) < VenueRules.distanceMeters($1.location, center) }
    }

    func matchChanges(matchId: String) -> AsyncThrowingStream<Match?, Error> {
        AsyncThrowingStream { continuation in
            let registration = db.document("matches/\(matchId)").addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let snapshot, snapshot.exists {
                    if let match = try? snapshot.decoded(as: Match.self) { continuation.yield(match) }
                } else {
                    continuation.yield(nil)
                }
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func matches(ids: [String]) async throws -> [Match] {
        var result: [Match] = []
        for chunk in stride(from: 0, to: ids.count, by: 30).map({ Array(ids[$0..<min($0 + 30, ids.count)]) }) {
            let snapshot = try await db.collection("matches").whereField(FieldPath.documentID(), in: chunk).getDocuments()
            result += try snapshot.documents.map { try $0.decoded(as: Match.self) }
        }
        return result
    }

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
