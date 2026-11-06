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
    /// R6 (1.19): Matches this Player hosts, live. Ended ones are filtered on the device.
    func hostedChanges(hostId: String) -> AsyncThrowingStream<[Match], Error>
    /// W3 (1.11): the Match, the Host's own approved RSVP, and the Match chat, in one batch. Returns the Match ID.
    func publish(_ draft: MatchDraft, host: UserProfile) async throws -> String
    func saveEdits(_ match: Match, edits: MatchEdits, recipients: [String], hostId: String) async throws
    func cancel(_ match: Match, reason: String, recipients: [String], hostId: String) async throws
    func transferHost(_ match: Match, to player: RSVP, hostId: String) async throws
    func checkIn(_ match: Match, attendedByPlayer: [String: Bool], hostId: String) async throws
}

struct MatchEdits: Equatable, Sendable {
    var startTime: Date
    var endTime: Date
    var playerLimit: Int
    var joinType: JoinType
    var notes: String?
    var venue: Venue?
    var notify: Bool
    var hostNote: String?
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

    func hostedChanges(hostId: String) -> AsyncThrowingStream<[Match], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("matches")
                .whereField("hostId", isEqualTo: hostId)
                .whereField("status", isEqualTo: MatchStatus.scheduled.rawValue)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        let matches = snapshot.documents.compactMap { try? $0.decoded(as: Match.self) }
                        continuation.yield(matches.sorted { $0.startTime < $1.startTime })
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func saveEdits(_ match: Match, edits: MatchEdits, recipients: [String], hostId: String) async throws {
        guard let matchId = match.id, match.hostId == hostId, edits.playerLimit >= match.joinedCount else { throw PublishError.incomplete }
        let changes = MatchChange.changes(from: match, edits: edits)
        let batch = db.batch()
        var fields: [String: Any] = [
            "startTime": Timestamp(date: edits.startTime),
            "endTime": Timestamp(date: edits.endTime),
            "playerLimit": edits.playerLimit,
            "joinType": edits.joinType.rawValue,
            "notes": edits.notes ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let venue = edits.venue {
            fields["venueId"] = venue.id ?? ""
            fields["venueName"] = venue.name
            fields["location"] = ["latitude": venue.location.latitude, "longitude": venue.location.longitude]
            fields["geohash"] = Geohash.encode(latitude: venue.location.latitude, longitude: venue.location.longitude)
            fields["isIndoor"] = venue.isIndoor
            fields["surface"] = venue.surface
            fields["hasLights"] = venue.hasLights
        }
        batch.updateData(fields, forDocument: db.document("matches/\(matchId)"))
        let notable = changes.filter { $0.field != "Description" }
        if edits.notify, !notable.isEmpty {
            let payload = changes.map { ["field": $0.field, "oldValue": $0.oldValue, "newValue": $0.newValue] }
            for userId in recipients where userId != hostId {
                batch.setData(NotificationWriter.fields(
                    type: .matchUpdated, title: "\(match.title) was updated",
                    body: notable.map { "\($0.field): \($0.oldValue) → \($0.newValue)" }.joined(separator: "\n"),
                    matchId: matchId, fromUserId: hostId, hostNote: edits.hostNote, changes: payload
                ), forDocument: db.collection("users/\(userId)/notifications").document())
            }
        }
        try await batch.commit()
    }

    func cancel(_ match: Match, reason: String, recipients: [String], hostId: String) async throws {
        guard let matchId = match.id, match.hostId == hostId, (1...200).contains(reason.count) else { throw PublishError.incomplete }
        let batch = db.batch()
        batch.updateData([
            "status": MatchStatus.cancelled.rawValue,
            "cancelReason": reason,
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: db.document("matches/\(matchId)"))
        for userId in recipients where userId != hostId {
            batch.setData(NotificationWriter.fields(
                type: .matchCancelled, title: "\(match.title) was cancelled",
                body: reason, matchId: matchId, fromUserId: hostId, hostNote: reason
            ), forDocument: db.collection("users/\(userId)/notifications").document())
        }
        try await batch.commit()
    }

    func transferHost(_ match: Match, to player: RSVP, hostId: String) async throws {
        guard let matchId = match.id, match.hostId == hostId, player.status == .approved, !player.isHost else { throw PublishError.incomplete }
        let batch = db.batch()
        batch.updateData([
            "hostId": player.userId,
            "hostName": player.displayName,
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: db.document("matches/\(matchId)"))
        batch.updateData(["isHost": false], forDocument: db.document("matches/\(matchId)/rsvps/\(hostId)"))
        batch.updateData(["isHost": true], forDocument: db.document("matches/\(matchId)/rsvps/\(player.userId)"))
        batch.setData(NotificationWriter.fields(
            type: .hostTransferred, title: "You're now the Host of \(match.title)",
            body: "You can edit, approve, and cancel this Match.", matchId: matchId, fromUserId: hostId
        ), forDocument: db.collection("users/\(player.userId)/notifications").document())
        try await batch.commit()
    }

    func checkIn(_ match: Match, attendedByPlayer: [String: Bool], hostId: String) async throws {
        guard let matchId = match.id, match.hostId == hostId else { throw PublishError.incomplete }
        let batch = db.batch()
        batch.updateData(["checkedInAt": FieldValue.serverTimestamp(), "updatedAt": FieldValue.serverTimestamp()], forDocument: db.document("matches/\(matchId)"))
        for (userId, attended) in attendedByPlayer {
            let didAttend = userId == hostId ? true : attended
            batch.updateData(["checkedIn": true, "attended": didAttend], forDocument: db.document("matches/\(matchId)/rsvps/\(userId)"))
        }
        try await batch.commit()
    }
}
