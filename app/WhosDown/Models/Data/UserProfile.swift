import Foundation

/// `users/{userId}`: a Player's public profile.
nonisolated struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var displayName: String
    var displayNameLowercase: String
    var photoURL: String?
    var bio: String?
    var homeArea: String?
    var playStyles: [PlayStyle]
    /// Sport raw value → level, e.g. `["soccer": .intermediate]`.
    var sportLevels: [String: SkillLevel]
    var customSportName: String?
    var createdAt: Date
    /// Null until onboarding (1.4) is finished.
    var onboardedAt: Date?

    var initials: String {
        displayName.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
    }
}

/// `users/{userId}/private/settings`: readable and writable by the owner only.
nonisolated struct UserSettings: Codable, Hashable, Sendable {
    var email: String
    var notificationPrefs: NotificationPrefs
    var searchRadiusMiles: Double

    struct NotificationPrefs: Codable, Hashable, Sendable {
        var approvals: Bool
        var timeOrLocationChanges: Bool
        var cancellations: Bool
    }
}
