import FirebaseFirestore
import Foundation

/// Why a join, request, or decision was refused. Messages are shown as-is.
/// One RSVP plus the Match it belongs to. The Match id is the parent document, not a field.
struct MyRSVP: Hashable, Sendable {
    var matchId: String
    var rsvp: RSVP
}

enum RSVPWriteError: LocalizedError, Equatable, CustomNSError {
    case spotTaken
    case closed
    case notAllowed
    case missing

    var errorDescription: String? {
        switch self {
        case .spotTaken: "That spot was just taken"
        case .closed: "This Match is no longer open"
        case .notAllowed: "You can't do that"
        case .missing: "This Match is no longer available"
        }
    }

    static var errorDomain: String { "WhosDown.RSVPWriteError" }

    var errorCode: Int {
        switch self {
        case .spotTaken: 1
        case .closed: 2
        case .notAllowed: 3
        case .missing: 4
        }
    }
}

/// Reads and writes `matches/{matchId}/rsvps/{userId}`.
protocol RSVPRepository {
    /// R3 (1.10): approved RSVPs of a Match, live, Host first then in the order they joined.
    func approvedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error>
    /// R5: the Player's approved RSVPs across all Matches (1.5 "Next up", later 1.19).
    func myApprovedMatchIds(userId: String) async throws -> [String]
    /// R5 for My Matches (1.19): every RSVP of this Player, with its Match id.
    func myRSVPs(userId: String) async throws -> [MyRSVP]
    /// The signed-in Player's RSVP for one Match, live. Nil when they have none.
    func myRSVPChanges(matchId: String, userId: String) -> AsyncThrowingStream<RSVP?, Error>
    /// Pending Join requests, oldest first (1.15).
    func pendingChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error>
    /// Waitlisted RSVPs (1.17). Order them with `waitlistIds` in the view.
    func waitlistedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error>
    /// W6 open join: an approved RSVP and `joinedCount + 1` in one transaction.
    func joinOpen(matchId: String, player: UserProfile, sport: Sport) async throws
    /// W6 request: a pending RSVP and `pendingCount + 1` in one transaction.
    func requestToJoin(matchId: String, player: UserProfile, sport: Sport, note: String?) async throws
    /// W7: the Host approves a pending request.
    func approve(matchId: String, userId: String, hostId: String) async throws
    /// W7: the Host declines a pending request, with an optional message.
    func decline(matchId: String, userId: String, hostId: String, message: String?) async throws
    /// W8: the Player sets their own RSVP to `left` and the matching counter drops by 1.
    func leave(matchId: String, userId: String) async throws
    /// Join the waitlist of a Full Match (1.17).
    func joinWaitlist(matchId: String, player: UserProfile, sport: Sport) async throws
    /// The Host approves someone from the waitlist while a spot is free (1.17).
    func approveFromWaitlist(matchId: String, userId: String, hostId: String) async throws
    /// Every RSVP on a Match. Cancel notifies approved, pending, and waitlisted Players (1.18).
    func participants(matchId: String) async throws -> [RSVP]
    /// Approved RSVPs, for check-in (1.27).
    func approvedOnce(matchId: String) async throws -> [RSVP]
}

final class FirebaseRSVPRepository: RSVPRepository {
    private let db = Firestore.firestore()

    func approvedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("matches/\(matchId)/rsvps")
                .whereField("status", isEqualTo: RSVPStatus.approved.rawValue)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        // Wait for the server: the local cache may hold only some of the roster (e.g. the Player's
                        // own RSVP from another query), which would flash a wrong "1 joined".
                        if snapshot.metadata.isFromCache { return }
                        let rsvps = snapshot.documents.compactMap { try? $0.decoded(as: RSVP.self) }
                        continuation.yield(RosterRules.ordered(rsvps))
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func myApprovedMatchIds(userId: String) async throws -> [String] {
        let snapshot = try await db.collectionGroup("rsvps")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: RSVPStatus.approved.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { $0.reference.parent.parent?.documentID }
    }

    func myRSVPs(userId: String) async throws -> [MyRSVP] {
        let snapshot = try await db.collectionGroup("rsvps")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            guard let matchId = document.reference.parent.parent?.documentID,
                  let rsvp = try? document.decoded(as: RSVP.self) else { return nil }
            return MyRSVP(matchId: matchId, rsvp: rsvp)
        }
    }

    func myRSVPChanges(matchId: String, userId: String) -> AsyncThrowingStream<RSVP?, Error> {
        AsyncThrowingStream { continuation in
            let registration = db.document("matches/\(matchId)/rsvps/\(userId)").addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let snapshot, snapshot.exists {
                    continuation.yield(try? snapshot.decoded(as: RSVP.self))
                } else {
                    continuation.yield(nil)
                }
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func pendingChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("matches/\(matchId)/rsvps")
                .whereField("status", isEqualTo: RSVPStatus.pending.rawValue)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        if snapshot.metadata.isFromCache { return }
                        let requests = snapshot.documents.compactMap { try? $0.decoded(as: RSVP.self) }
                            .sorted { $0.requestedAt < $1.requestedAt }
                        continuation.yield(requests)
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func waitlistedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("matches/\(matchId)/rsvps")
                .whereField("status", isEqualTo: RSVPStatus.waitlisted.rawValue)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        if snapshot.metadata.isFromCache { return }
                        continuation.yield(snapshot.documents.compactMap { try? $0.decoded(as: RSVP.self) })
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func joinOpen(matchId: String, player: UserProfile, sport: Sport) async throws {
        try await write(matchId: matchId, userId: player.id ?? "") { transaction, match, existing in
            guard match.joinType == .open, match.status == .scheduled, match.startTime > .now,
                  match.hostId != player.id else { throw RSVPWriteError.closed }
            if match.isFull { throw RSVPWriteError.spotTaken }
            if let existing, existing.status != .left { throw RSVPWriteError.notAllowed }
            let preview = Self.preview(match.attendeePreview, adding: player.initials)
            transaction.updateData([
                "joinedCount": match.joinedCount + 1,
                "attendeePreview": preview,
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.setData(self.rsvpFields(
                player: player, sport: sport, status: .approved, note: nil, responded: true
            ), forDocument: self.rsvpRef(matchId, player.id ?? ""))
        }
    }

    func requestToJoin(matchId: String, player: UserProfile, sport: Sport, note: String?) async throws {
        let cleaned = JoinRules.cleanedNote(note ?? "")
        if let note, JoinRules.cleanedNote(note) == nil, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw RSVPWriteError.notAllowed
        }
        try await write(matchId: matchId, userId: player.id ?? "") { transaction, match, existing in
            guard match.joinType == .approvalRequired, match.status == .scheduled, match.startTime > .now,
                  match.hostId != player.id, !match.isFull else { throw RSVPWriteError.closed }
            if existing?.status == .pending { return }
            if let existing, existing.status != .left { throw RSVPWriteError.notAllowed }
            transaction.updateData([
                "pendingCount": match.pendingCount + 1,
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.setData(self.rsvpFields(
                player: player, sport: sport, status: .pending, note: cleaned, responded: false
            ), forDocument: self.rsvpRef(matchId, player.id ?? ""))
        }
    }

    func approve(matchId: String, userId: String, hostId: String) async throws {
        try await write(matchId: matchId, userId: userId) { transaction, match, existing in
            guard match.hostId == hostId, match.status == .scheduled, match.startTime > .now else { throw RSVPWriteError.closed }
            guard existing?.status == .pending else { throw RSVPWriteError.missing }
            guard match.joinedCount + 1 <= match.playerLimit else { throw RSVPWriteError.spotTaken }
            let preview = Self.preview(match.attendeePreview, adding: initials(of: existing?.displayName ?? ""))
            transaction.updateData([
                "joinedCount": match.joinedCount + 1,
                "pendingCount": max(match.pendingCount - 1, 0),
                "attendeePreview": preview,
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.updateData([
                "status": RSVPStatus.approved.rawValue,
                "respondedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.rsvpRef(matchId, userId))
            transaction.setData(NotificationWriter.fields(
                type: .approved, title: "You're in: \(match.title)",
                body: "The Host approved your request.", matchId: matchId, fromUserId: hostId
            ), forDocument: self.db.collection("users/\(userId)/notifications").document())
        }
    }

    func decline(matchId: String, userId: String, hostId: String, message: String?) async throws {
        let message = JoinRules.cleanedNote(message ?? "")
        try await write(matchId: matchId, userId: userId) { transaction, match, existing in
            guard match.hostId == hostId else { throw RSVPWriteError.notAllowed }
            guard existing?.status == .pending else { throw RSVPWriteError.missing }
            transaction.updateData([
                "pendingCount": max(match.pendingCount - 1, 0),
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.updateData([
                "status": RSVPStatus.declined.rawValue,
                "respondedAt": FieldValue.serverTimestamp(),
                "hostResponse": message ?? NSNull(),
            ], forDocument: self.rsvpRef(matchId, userId))
            transaction.setData(NotificationWriter.fields(
                type: .declined, title: "Request declined: \(match.title)",
                body: message ?? "The Host declined your request.",
                matchId: matchId, fromUserId: hostId, hostNote: message
            ), forDocument: self.db.collection("users/\(userId)/notifications").document())
        }
    }

    func leave(matchId: String, userId: String) async throws {
        try await write(matchId: matchId, userId: userId) { transaction, match, existing in
            guard match.startTime > .now, match.hostId != userId else { throw RSVPWriteError.closed }
            guard let existing, existing.status == .approved || existing.status == .pending || existing.status == .waitlisted else {
                throw RSVPWriteError.notAllowed
            }
            var updates: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
            switch existing.status {
            case .approved:
                let promoted = WaitlistRules.promotedIds(
                    joinType: match.joinType, waitlistIds: match.waitlistIds, spotsOpened: 1,
                    hasStarted: match.startTime <= .now
                )
                var waitlist = match.waitlistIds
                var joined = max(match.joinedCount - 1, 0)
                for id in promoted {
                    transaction.updateData([
                        "status": RSVPStatus.approved.rawValue,
                        "respondedAt": FieldValue.serverTimestamp(),
                    ], forDocument: self.rsvpRef(matchId, id))
                    if !waitlist.isEmpty { waitlist.removeFirst() }
                    joined += 1
                    transaction.setData(NotificationWriter.fields(
                        type: .approved, title: "You're in from the waitlist: \(match.title)",
                        body: "A spot opened and you're in.", matchId: matchId, fromUserId: userId
                    ), forDocument: self.db.collection("users/\(id)/notifications").document())
                }
                updates["joinedCount"] = joined
                updates["attendeePreview"] = match.attendeePreview.filter { $0 != initials(of: existing.displayName) }
                if match.joinType == .open, !promoted.isEmpty {
                    updates["waitlistIds"] = waitlist
                    updates["waitlistCount"] = waitlist.count
                } else if match.joinType == .approvalRequired, !match.waitlistIds.isEmpty || match.pendingCount > 0 {
                    let waiting = match.waitlistCount + match.pendingCount
                    transaction.setData(NotificationWriter.fields(
                        type: .spotOpened, title: "A spot opened in \(match.title)",
                        body: "\(waiting) waiting", matchId: matchId, fromUserId: userId
                    ), forDocument: self.db.collection("users/\(match.hostId)/notifications").document())
                }
            case .pending:
                updates["pendingCount"] = max(match.pendingCount - 1, 0)
            case .waitlisted:
                updates["waitlistCount"] = max(match.waitlistCount - 1, 0)
                updates["waitlistIds"] = match.waitlistIds.filter { $0 != userId }
            case .declined, .left:
                break
            }
            transaction.updateData(updates, forDocument: self.matchRef(matchId))
            transaction.updateData([
                "status": RSVPStatus.left.rawValue,
            ], forDocument: self.rsvpRef(matchId, userId))
        }
    }

    func joinWaitlist(matchId: String, player: UserProfile, sport: Sport) async throws {
        try await write(matchId: matchId, userId: player.id ?? "") { transaction, match, existing in
            guard match.isFull, match.waitlistEnabled, match.status == .scheduled, match.startTime > .now,
                  match.hostId != player.id, match.waitlistIds.count < WaitlistRules.cap else { throw RSVPWriteError.closed }
            if let existing, existing.status != .left { throw RSVPWriteError.notAllowed }
            transaction.updateData([
                "waitlistIds": match.waitlistIds + [player.id ?? ""],
                "waitlistCount": match.waitlistCount + 1,
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.setData(self.rsvpFields(
                player: player, sport: sport, status: .waitlisted, note: nil, responded: false
            ), forDocument: self.rsvpRef(matchId, player.id ?? ""))
        }
    }

    func approveFromWaitlist(matchId: String, userId: String, hostId: String) async throws {
        try await write(matchId: matchId, userId: userId) { transaction, match, existing in
            guard match.hostId == hostId, match.joinedCount < match.playerLimit, match.waitlistIds.contains(userId),
                  existing?.status == .waitlisted else { throw RSVPWriteError.notAllowed }
            let preview = Self.preview(match.attendeePreview, adding: initials(of: existing?.displayName ?? ""))
            transaction.updateData([
                "joinedCount": match.joinedCount + 1,
                "waitlistCount": max(match.waitlistCount - 1, 0),
                "waitlistIds": match.waitlistIds.filter { $0 != userId },
                "attendeePreview": preview,
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.matchRef(matchId))
            transaction.updateData([
                "status": RSVPStatus.approved.rawValue,
                "respondedAt": FieldValue.serverTimestamp(),
            ], forDocument: self.rsvpRef(matchId, userId))
            transaction.setData(NotificationWriter.fields(
                type: .approved, title: "You're in: \(match.title)",
                body: "The Host let you in from the waitlist.", matchId: matchId, fromUserId: hostId
            ), forDocument: self.db.collection("users/\(userId)/notifications").document())
        }
    }

    func participants(matchId: String) async throws -> [RSVP] {
        let snapshot = try await db.collection("matches/\(matchId)/rsvps").getDocuments()
        return try snapshot.documents.map { try $0.decoded(as: RSVP.self) }
    }

    func approvedOnce(matchId: String) async throws -> [RSVP] {
        let snapshot = try await db.collection("matches/\(matchId)/rsvps")
            .whereField("status", isEqualTo: RSVPStatus.approved.rawValue)
            .getDocuments()
        return try snapshot.documents.map { try $0.decoded(as: RSVP.self) }
    }

    private func matchRef(_ matchId: String) -> DocumentReference {
        db.document("matches/\(matchId)")
    }

    private func rsvpRef(_ matchId: String, _ userId: String) -> DocumentReference {
        db.document("matches/\(matchId)/rsvps/\(userId)")
    }

    /// Re-reads the Match inside the transaction, then runs `body`. `body` throws `RSVPWriteError`.
    private func write(
        matchId: String, userId: String,
        body: @escaping (Transaction, Match, RSVP?) throws -> Void
    ) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let matchSnap = try transaction.getDocument(self.matchRef(matchId))
                guard matchSnap.exists, var match = try? matchSnap.decoded(as: Match.self) else {
                    throw RSVPWriteError.missing
                }
                match.id = matchId
                let rsvpSnap = try transaction.getDocument(self.rsvpRef(matchId, userId))
                let existing = rsvpSnap.exists ? try rsvpSnap.decoded(as: RSVP.self) : nil
                try body(transaction, match, existing)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func rsvpFields(
        player: UserProfile, sport: Sport, status: RSVPStatus, note: String?, responded: Bool
    ) -> [String: Any] {
        let level = (player.sportLevels[sport.rawValue] ?? .allLevels).rawValue
        let now = FieldValue.serverTimestamp()
        return [
            "userId": player.id ?? "",
            "displayName": player.displayName,
            "skillLevel": level,
            "status": status.rawValue,
            "isHost": false,
            "noteToHost": note ?? NSNull(),
            "hostResponse": NSNull(),
            "requestedAt": now,
            "respondedAt": responded ? now : NSNull(),
            "checkedIn": false,
            "attended": NSNull(),
        ]
    }

    private static func preview(_ current: [String], adding initials: String) -> [String] {
        guard current.count < 6, !current.contains(initials) else { return current }
        return current + [initials]
    }
}

private func initials(of name: String) -> String {
    name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
}

/// Roster order (1.10 rule 1): the Host first, then Players in the order they joined.
nonisolated enum RosterRules {
    static func ordered(_ rsvps: [RSVP]) -> [RSVP] {
        rsvps.sorted { a, b in
            if a.isHost != b.isHost { return a.isHost }
            return (a.respondedAt ?? a.requestedAt) < (b.respondedAt ?? b.requestedAt)
        }
    }
}
