import Foundation

/// `conversations/{matchId}`: the Match chat (D39). V2 reuses this collection for direct and group chats.
nonisolated struct Conversation: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var type: String
    var title: String
    var matchId: String?
    var lastMessageText: String?
    var lastMessageAt: Date?
}

/// `conversations/{id}/messages/{messageId}`.
nonisolated struct Message: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var sentAt: Date
}
