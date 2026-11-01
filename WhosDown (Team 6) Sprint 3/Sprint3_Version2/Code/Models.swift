import Foundation
import FirebaseFirestore

// WhosDown app models. Each struct matches one Firestore document type
// and decodes directly with `document.data(as:)`.

// MARK: - Shared enums

enum Sport: String, Codable, CaseIterable {
  case soccer, basketball, tennis, volleyball, pickleball, baseball, football, ultimate, other
}

enum SkillLevel: String, Codable, CaseIterable {
  case beginner, casual, allLevels, intermediate, competitive
}

enum PlayStyle: String, Codable, CaseIterable {
  case social, competitive, learning
}

enum Visibility: String, Codable {
  case `public`, `private`
}

enum JoinType: String, Codable {
  case open, approvalRequired
}

enum GameStatus: String, Codable {
  case scheduled, cancelled, completed
}

enum RSVPStatus: String, Codable {
  case pending, approved, declined, waitlisted, left, removed
}

enum AudienceSetting: String, Codable {
  case everyone, whosDownPlayers, friendsAndTeammates, friends, nobody
}

enum FeedbackTag: String, Codable, CaseIterable {
  case reliable, goodSport, communicative, welcoming, competitive, helpful
}

// MARK: - users/{userId}

struct AppUser: Codable, Identifiable {
  @DocumentID var id: String?
  var displayName: String
  var displayNameLowercase: String
  var photoURL: String?
  var bio: String
  var homeArea: String
  var schoolLine: String?
  var position: String?
  var isVerified: Bool
  var isGuest: Bool
  var playStyles: [PlayStyle]
  var sportLevels: [String: SkillLevel]
  var stats: PlayerStats
  var createdAt: Date

  var initials: String {
    displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
  }
}

struct PlayerStats: Codable {
  var gamesRSVPd: Int
  var gamesAttended: Int
  var gamesHosted: Int
  var mvpCount: Int
  var playAgainYes: Int
  var playAgainTotal: Int
  var feedbackTagCounts: [String: Int]
  var recentFeedback: [String]
  var avgResponseMinutes: Int?

  var reliability: Double? {
    gamesRSVPd == 0 ? nil : Double(gamesAttended) / Double(gamesRSVPd)
  }
}

// MARK: - users/{userId}/private/settings

struct UserSettings: Codable {
  var email: String
  var notificationPrefs: NotificationPrefs
  var newGameAlert: NewGameAlertRule?
  var privacy: PrivacySettings
  var blockedUserIds: [String]
  var favoriteVenueIds: [String]
  var pinnedGroupIds: [String]
  var searchRadiusMiles: Double
  var fcmTokens: [String]
}

struct NotificationPrefs: Codable {
  var approvals: Bool
  var timeOrLocationChanges: Bool
  var cancellations: Bool
  var reviewReminders: Bool
  var newNearbyGames: Bool
  var groupActivity: Bool
  var messages: Bool
}

struct NewGameAlertRule: Codable {
  var sports: [Sport]
  var radiusMiles: Double
  var weekdaysOnly: Bool
  var earliestHour: Int
  var skillLevels: [SkillLevel]
}

struct PrivacySettings: Codable {
  var gameActivity: AudienceSetting
  var profileVisibility: AudienceSetting
  var directMessages: AudienceSetting
  var friendRequests: AudienceSetting
}

// MARK: - users/{userId}/friends/{friendId}

enum FriendStatus: String, Codable {
  case requestSent, requestReceived, friends
}

struct Friendship: Codable, Identifiable {
  @DocumentID var id: String?
  var displayName: String
  var status: FriendStatus
  var mutualCount: Int
  var since: Date
}

// MARK: - users/{userId}/notifications/{notificationId}

enum NotificationType: String, Codable {
  case approved, declined, gameUpdated, gameCancelled, spotOpen, message, groupActivity, reviewReminder, newGame
}

struct AppNotification: Codable, Identifiable {
  @DocumentID var id: String?
  var type: NotificationType
  var title: String
  var body: String
  var gameId: String?
  var groupId: String?
  var conversationId: String?
  var change: GameChange?
  var expiresAt: Date?
  var isRead: Bool
  var createdAt: Date
}

struct GameChange: Codable {
  var field: String
  var oldValue: String
  var newValue: String
  var hostNote: String?
}

// MARK: - venues/{venueId}

struct Venue: Codable, Identifiable {
  @DocumentID var id: String?
  var name: String
  var address: String
  var location: GeoPoint
  var geohash: String
  var isIndoor: Bool
  var surface: String?
  var hasLights: Bool
  var sports: [Sport]
  var createdBy: String
}

// MARK: - games/{gameId}

struct Game: Codable, Identifiable {
  @DocumentID var id: String?
  var title: String
  var titleLowercase: String
  var sport: Sport
  var customSportName: String?
  var description: String
  var notes: String?
  var hostId: String
  var hostName: String
  var groupId: String?

  var venueId: String
  var venueName: String
  var location: GeoPoint
  var geohash: String
  var isIndoor: Bool
  var surface: String?
  var hasLights: Bool

  var startTime: Date
  var endTime: Date

  var skillLevel: SkillLevel
  var visibility: Visibility
  var joinType: JoinType
  var priceCents: Int
  var playerLimit: Int
  var waitlistEnabled: Bool

  var joinedCount: Int
  var pendingCount: Int
  var waitlistCount: Int
  var attendeePreview: [String]

  var fieldReserved: Bool
  var reservationWindow: String?
  var facilityNote: String?
  var mediaURLs: [String]

  var status: GameStatus
  var cancelReason: String?
  var conversationId: String
  var createdAt: Date
  var updatedAt: Date

  var isFree: Bool { priceCents == 0 }
  var isFull: Bool { joinedCount >= playerLimit }
  var spotsLeft: Int { max(playerLimit - joinedCount, 0) }
  var sportName: String { customSportName ?? sport.rawValue.capitalized }
}

// MARK: - games/{gameId}/rsvps/{userId}

struct RSVP: Codable, Identifiable {
  @DocumentID var id: String?
  var userId: String
  var displayName: String
  var reliability: Double?
  var skillLevel: SkillLevel?
  var status: RSVPStatus
  var isHost: Bool
  var noteToHost: String?
  var hostResponse: String?
  var waitlistPosition: Int?
  var spotOfferExpiresAt: Date?
  var attended: Bool?
  var personalNote: String?
  var requestedAt: Date
  var respondedAt: Date?
}

// MARK: - groups/{groupId}

enum MembershipType: String, Codable {
  case open, requestToJoin
}

struct PlayGroup: Codable, Identifiable {
  @DocumentID var id: String?
  var name: String
  var nameLowercase: String
  var description: String
  var photoURL: String?
  var sports: [Sport]
  var localArea: String
  var visibility: Visibility
  var membershipType: MembershipType
  var ownerId: String
  var memberCount: Int
  var conversationId: String
  var createdAt: Date
}

// MARK: - groups/{groupId}/members/{userId}

enum GroupRole: String, Codable {
  case owner, admin, member, pending
}

struct GroupMember: Codable, Identifiable {
  @DocumentID var id: String?
  var displayName: String
  var role: GroupRole
  var joinedAt: Date
}

// MARK: - conversations/{conversationId}

enum ConversationType: String, Codable {
  case direct, game, group
}

struct Conversation: Codable, Identifiable {
  @DocumentID var id: String?
  var type: ConversationType
  var title: String
  var gameId: String?
  var groupId: String?
  var participantIds: [String]
  var lastMessageText: String?
  var lastMessageAt: Date?
  var unreadCounts: [String: Int]
}

// MARK: - conversations/{conversationId}/messages/{messageId}

struct Message: Codable, Identifiable {
  @DocumentID var id: String?
  var senderId: String
  var senderName: String
  var text: String
  var mediaURL: String?
  var sentAt: Date
}

// MARK: - reviews/{reviewId}

struct Review: Codable, Identifiable {
  @DocumentID var id: String?
  var gameId: String
  var reviewerId: String
  var revieweeId: String
  var isMVP: Bool
  var playAgain: Bool
  var tags: [FeedbackTag]
  var comment: String?
  var createdAt: Date
}

// MARK: - reports/{reportId}

enum ReportReason: String, Codable {
  case harassment, noShow, misleadingEvent, other
}

enum ReportStatus: String, Codable {
  case open, reviewing, resolved
}

struct Report: Codable, Identifiable {
  @DocumentID var id: String?
  var reporterId: String
  var reportedUserId: String
  var gameId: String?
  var reason: ReportReason
  var details: String?
  var status: ReportStatus
  var createdAt: Date
}
