import FirebaseFirestore
import Foundation

/// A data model whose `id` is its Firestore document ID. The ID isn't stored in the document,
/// so decode with `snapshot.decoded(as:)`, which fills it in. (Replaces `@DocumentID`, whose
/// wrapper isn't `Sendable`; see lessons-learned 2026-11-02.)
nonisolated protocol FirestoreDocument: Decodable {
    var id: String? { get set }
}

nonisolated extension UserProfile: FirestoreDocument {}
nonisolated extension Venue: FirestoreDocument {}
nonisolated extension Match: FirestoreDocument {}
nonisolated extension RSVP: FirestoreDocument {}
nonisolated extension AppNotification: FirestoreDocument {}
nonisolated extension Conversation: FirestoreDocument {}
nonisolated extension Message: FirestoreDocument {}
nonisolated extension Report: FirestoreDocument {}

extension DocumentSnapshot {
    func decoded<T: FirestoreDocument>(as type: T.Type) throws -> T {
        var value = try data(as: type)
        value.id = documentID
        return value
    }
}
