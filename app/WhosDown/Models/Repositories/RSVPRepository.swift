import FirebaseFirestore
import Foundation

/// Reads and writes `matches/{matchId}/rsvps/{userId}`. Phase 4 adds join, request, approve, and leave.
protocol RSVPRepository {
    /// R3 (1.10): approved RSVPs of a Match, live, Host first then in the order they joined.
    func approvedChanges(matchId: String) -> AsyncThrowingStream<[RSVP], Error>
    /// R5: the Player's approved RSVPs across all Matches (1.5 "Next up", later 1.19).
    func myApprovedMatchIds(userId: String) async throws -> [String]
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
