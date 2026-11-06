import FirebaseFirestore
import Foundation

/// Match chat (1.20). Phase 4 only reads the last-message preview for the Host dashboard.
protocol ChatRepository {
    func conversationChanges(matchId: String) -> AsyncThrowingStream<Conversation?, Error>
    /// R13: the newest messages, live. Older pages come from `olderMessages`.
    func messageChanges(matchId: String) -> AsyncThrowingStream<[Message], Error>
    func olderMessages(matchId: String, before: Date) async throws -> [Message]
    /// W11: a message plus the conversation preview, in one batch.
    func send(matchId: String, senderId: String, senderName: String, text: String) async throws
}

final class FirebaseChatRepository: ChatRepository {
    private let db = Firestore.firestore()

    func conversationChanges(matchId: String) -> AsyncThrowingStream<Conversation?, Error> {
        AsyncThrowingStream { continuation in
            let registration = db.document("conversations/\(matchId)").addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let snapshot, snapshot.exists {
                    continuation.yield(try? snapshot.decoded(as: Conversation.self))
                } else {
                    continuation.yield(nil)
                }
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func messageChanges(matchId: String) -> AsyncThrowingStream<[Message], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("conversations/\(matchId)/messages")
                .order(by: "sentAt", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        let messages = snapshot.documents.compactMap { try? $0.decoded(as: Message.self) }
                        continuation.yield(messages.sorted { $0.sentAt < $1.sentAt })
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func olderMessages(matchId: String, before: Date) async throws -> [Message] {
        let snapshot = try await db.collection("conversations/\(matchId)/messages")
            .order(by: "sentAt", descending: true)
            .start(after: [Timestamp(date: before)])
            .limit(to: 50)
            .getDocuments()
        return try snapshot.documents.map { try $0.decoded(as: Message.self) }.sorted { $0.sentAt < $1.sentAt }
    }

    func send(matchId: String, senderId: String, senderName: String, text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 1000 else { return }
        let message = db.collection("conversations/\(matchId)/messages").document()
        let batch = db.batch()
        batch.setData([
            "senderId": senderId,
            "senderName": senderName,
            "text": trimmed,
            "sentAt": FieldValue.serverTimestamp(),
        ], forDocument: message)
        batch.updateData([
            "lastMessageText": trimmed,
            "lastMessageAt": FieldValue.serverTimestamp(),
        ], forDocument: db.document("conversations/\(matchId)"))
        try await batch.commit()
    }
}
