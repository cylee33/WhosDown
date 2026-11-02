import FirebaseFirestore
import FirebaseStorage
import Foundation

/// The fields a Player edits on their own profile (1.4 onboarding, 1.22 edit). Always saved together.
nonisolated struct ProfileFields: Equatable, Sendable {
    var displayName: String
    var photoURL: String?
    var bio: String?
    var homeArea: String?
    var playStyles: [PlayStyle]
    var sportLevels: [String: SkillLevel]
    var customSportName: String?

    init(_ profile: UserProfile) {
        displayName = profile.displayName
        photoURL = profile.photoURL
        bio = profile.bio
        homeArea = profile.homeArea
        playStyles = profile.playStyles
        sportLevels = profile.sportLevels
        customSportName = profile.customSportName
    }
}

/// Reads and writes `users/{userId}`, its owner-only `private/settings`, and the avatar in Storage.
protocol UserRepository {
    /// W1: the new Player's profile and private settings, in one batch.
    func createProfile(userId: String, displayName: String, email: String) async throws
    /// The profile now and on every change; nil while it doesn't exist yet.
    func profileChanges(userId: String) -> AsyncThrowingStream<UserProfile?, Error>
    /// R7: another Player's profile, read once (H10). Nil if it doesn't exist.
    func profile(userId: String) async throws -> UserProfile?
    /// Saves every editable profile field (1.4, 1.22).
    func updateProfile(userId: String, fields: ProfileFields) async throws
    /// Uploads a JPEG to `users/{userId}/avatar.jpg` and returns its download URL.
    func uploadAvatar(userId: String, jpegData: Data) async throws -> String
    /// W16: the three notification switches from H05.
    func saveNotificationPrefs(userId: String, prefs: UserSettings.NotificationPrefs) async throws
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

    func profile(userId: String) async throws -> UserProfile? {
        let snapshot = try await db.document("users/\(userId)").getDocument()
        return snapshot.exists ? try snapshot.decoded(as: UserProfile.self) : nil
    }

    func updateProfile(userId: String, fields: ProfileFields) async throws {
        try await db.document("users/\(userId)").updateData([
            "displayName": fields.displayName,
            "displayNameLowercase": fields.displayName.lowercased(),
            "photoURL": fields.photoURL ?? NSNull(),
            "bio": fields.bio ?? NSNull(),
            "homeArea": fields.homeArea ?? NSNull(),
            "playStyles": fields.playStyles.map(\.rawValue),
            "sportLevels": fields.sportLevels.mapValues(\.rawValue),
            "customSportName": fields.customSportName ?? NSNull(),
        ])
    }

    func uploadAvatar(userId: String, jpegData: Data) async throws -> String {
        let reference = Storage.storage().reference(withPath: "users/\(userId)/avatar.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await reference.putDataAsync(jpegData, metadata: metadata)
        return try await reference.downloadURL().absoluteString
    }

    func saveNotificationPrefs(userId: String, prefs: UserSettings.NotificationPrefs) async throws {
        try await db.document("users/\(userId)/private/settings").updateData([
            "notificationPrefs": [
                "approvals": prefs.approvals,
                "timeOrLocationChanges": prefs.timeOrLocationChanges,
                "cancellations": prefs.cancellations,
            ],
        ])
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
