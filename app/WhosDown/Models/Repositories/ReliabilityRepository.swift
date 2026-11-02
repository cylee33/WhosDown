import FirebaseFirestore
import Foundation

/// A Player's attendance record (GLOSSARY: Reliability). Counted when shown, never stored (D37).
nonisolated struct Reliability: Equatable, Sendable {
    /// Matches where the Host did Check-in and this Player was listed.
    var checkedIn: Int
    /// Of those, the ones where they attended. Also "Matches played" (1.22 rule 3).
    var attended: Int

    /// Whole percent, or nil for a Player with no checked-in Matches ("New player").
    var percent: Int? {
        checkedIn == 0 ? nil : Int((Double(attended) / Double(checkedIn) * 100).rounded())
    }

    /// "94% reliable" or "New player" (1.27 rule 9), used on H09, H10, H11, H21, H22, H36.
    var label: String {
        percent.map { "\($0)% reliable" } ?? "New player"
    }
}

/// R20: Reliability from count queries over the `rsvps` collection group (D37). Built in 1.22; 1.10 reuses it.
protocol ReliabilityRepository {
    func reliability(userId: String) async throws -> Reliability
}

final class FirebaseReliabilityRepository: ReliabilityRepository {
    private let db = Firestore.firestore()

    func reliability(userId: String) async throws -> Reliability {
        let checkedIn = db.collectionGroup("rsvps")
            .whereField("userId", isEqualTo: userId)
            .whereField("checkedIn", isEqualTo: true)
        async let checkedInCount = checkedIn.count.getAggregation(source: .server)
        async let attendedCount = checkedIn.whereField("attended", isEqualTo: true).count.getAggregation(source: .server)
        return try await Reliability(
            checkedIn: checkedInCount.count.intValue,
            attended: attendedCount.count.intValue
        )
    }
}
