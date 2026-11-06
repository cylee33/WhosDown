import FirebaseFirestore
import Foundation

/// Match chat (1.20). Phase 4 only reads the last-message preview for the Host dashboard.
protocol ChatRepository {
    func conversationChanges(matchId: String) -> AsyncThrowingStream<Conversation?, Error>
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
}
