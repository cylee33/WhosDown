import FirebaseFirestore
import Foundation

/// The shared notification writer (D38, 1.15). Later features call `send`; transactions that
/// must include the notification (approve, decline) use `fields` inside the same write.
protocol NotificationRepository {
    func send(
        to userId: String, type: NotificationType, title: String, body: String,
        matchId: String, fromUserId: String, hostNote: String?
    ) async throws
    func inbox(userId: String) -> AsyncThrowingStream<[AppNotification], Error>
    func markRead(userId: String, notificationId: String) async throws
    func markAllRead(userId: String, ids: [String]) async throws
    func delete(userId: String, notificationId: String) async throws
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

    func inbox(userId: String) -> AsyncThrowingStream<[AppNotification], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("users/\(userId)/notifications")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                    } else if let snapshot {
                        continuation.yield(snapshot.documents.compactMap { try? $0.decoded(as: AppNotification.self) })
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func markRead(userId: String, notificationId: String) async throws {
        try await db.document("users/\(userId)/notifications/\(notificationId)").updateData(["isRead": true])
    }

    func markAllRead(userId: String, ids: [String]) async throws {
        let batch = db.batch()
        for id in ids {
            batch.updateData(["isRead": true], forDocument: db.document("users/\(userId)/notifications/\(id)"))
        }
        if !ids.isEmpty { try await batch.commit() }
    }

    func delete(userId: String, notificationId: String) async throws {
        try await db.document("users/\(userId)/notifications/\(notificationId)").delete()
    }
}
