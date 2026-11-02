import FirebaseFirestore
import Foundation

/// Reads and writes `users/{userId}` and its owner-only `private/settings`.
/// 1.4 adds onboarding saves and the avatar upload; 1.22 adds profile edits.
protocol UserRepository {
    /// W1: the new Player's profile and private settings, in one batch.
    func createProfile(userId: String, displayName: String, email: String) async throws
    /// The profile now and on every change; nil while it doesn't exist yet.
    func profileChanges(userId: String) -> AsyncThrowingStream<UserProfile?, Error>
    /// Sets `onboardedAt`, which ends onboarding (1.4, H44).
    func completeOnboarding(userId: String) async throws
}

final class FirebaseUserRepository: UserRepository {
    private let db = Firestore.firestore()

    func createProfile(userId: String, displayName: String, email: String) async throws {
        let batch = db.batch()
        batch.setData([
            "displayName": displayName,
            "displayNameLowercase": displayName.lowercased(),
            "photoURL": NSNull(),
            "bio": NSNull(),
            "homeArea": NSNull(),
            "playStyles": [String](),
            "sportLevels": [String: String](),
            "customSportName": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "onboardedAt": NSNull(),
        ], forDocument: db.document("users/\(userId)"))
        batch.setData([
            "email": email,
            "notificationPrefs": ["approvals": true, "timeOrLocationChanges": true, "cancellations": true],
            "searchRadiusMiles": 3,
        ], forDocument: db.document("users/\(userId)/private/settings"))
        try await batch.commit()
    }

    func completeOnboarding(userId: String) async throws {
        try await db.document("users/\(userId)").updateData(["onboardedAt": FieldValue.serverTimestamp()])
    }

    func profileChanges(userId: String) -> AsyncThrowingStream<UserProfile?, Error> {
        AsyncThrowingStream { continuation in
            let registration = db.document("users/\(userId)").addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let snapshot, snapshot.exists {
                    // A just-created profile briefly has no server `createdAt`; wait for the confirmed one.
                    if let profile = try? snapshot.decoded(as: UserProfile.self) { continuation.yield(profile) }
                } else {
                    continuation.yield(nil)
                }
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }
}
