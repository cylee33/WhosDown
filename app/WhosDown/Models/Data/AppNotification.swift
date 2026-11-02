import Foundation

/// `users/{userId}/notifications/{id}`: one item in a Player's in-app inbox (1.21).
nonisolated struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var type: NotificationType
    var title: String
    var body: String
    var matchId: String?
    /// Who wrote it; security rules require it to be the signed-in sender (D38).
    var fromUserId: String
    var changes: [Change]?
    var hostNote: String?
    var isRead: Bool
    var createdAt: Date

    /// One edited field of a Match (1.18).
    struct Change: Codable, Hashable, Sendable {
        var field: String
        var oldValue: String
        var newValue: String
    }
}
