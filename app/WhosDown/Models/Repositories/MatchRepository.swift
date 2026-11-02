import FirebaseFirestore
import Foundation

/// Reads and writes `matches/{matchId}`. Each feature adds the methods it needs
/// (1.5 nearby query, 1.8 listener, 1.11 publish, 1.18 edit and cancel, 1.28 transfer).
protocol MatchRepository {
    /// Scheduled Matches that haven't ended, soonest first. Phase 0 placeholder for Discover; 1.5 replaces it with the nearby query.
    func upcomingMatches() async throws -> [Match]
}

final class FirebaseMatchRepository: MatchRepository {
    private let db = Firestore.firestore()

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
