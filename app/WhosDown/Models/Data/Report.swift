import Foundation

/// `reports/{reportId}`: written by Players, reviewed by Chris in the Firebase console (D44).
nonisolated struct Report: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var reporterId: String
    var reportedUserId: String?
    var matchId: String?
    var reason: Reason
    var details: String?
    var status: String
    var createdAt: Date

    enum Reason: String, Codable, CaseIterable, Sendable {
        case harassment, noShow, misleading, other
    }
}
