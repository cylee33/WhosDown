import FirebaseFirestore
import Foundation

/// The shared notification writer (D38, 1.15). Later features call `send`; transactions that
/// must include the notification (approve, decline) use `fields` inside the same write.
protocol NotificationRepository {
    func send(
        to userId: String, type: NotificationType, title: String, body: String,
        matchId: String, fromUserId: String, hostNote: String?
    ) async throws
}

enum NotificationWriter {
    static func fields(
        type: NotificationType, title: String, body: String, matchId: String,
        fromUserId: String, hostNote: String? = nil, changes: [[String: String]]? = nil
    ) -> [String: Any] {
        [
            "type": type.rawValue,
            "title": title,
            "body": body,
            "matchId": matchId,
            "fromUserId": fromUserId,
            "changes": changes ?? NSNull(),
            "hostNote": hostNote ?? NSNull(),
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp(),
        ]
    }
}

final class FirebaseNotificationRepository: NotificationRepository {
    private let db = Firestore.firestore()

    func send(
        to userId: String, type: NotificationType, title: String, body: String,
        matchId: String, fromUserId: String, hostNote: String?
    ) async throws {
        let ref = db.collection("users/\(userId)/notifications").document()
        try await ref.setData(NotificationWriter.fields(
            type: type, title: title, body: body, matchId: matchId, fromUserId: fromUserId, hostNote: hostNote
        ))
    }
}
