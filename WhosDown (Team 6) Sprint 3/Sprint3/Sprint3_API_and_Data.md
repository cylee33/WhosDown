# Sprint 3: APIs and Data

**WhosDown:** mobile app that makes pickup sports easier
Chris Lee, Jaimin Fee, Kurt Schimmel (Team 6)

**Files submitted with this document**

| File | What it shows |
|---|---|
| `WhosDownWeather.playground` | Open-Meteo request, JSON decoding into Codable structs, forecast for each game (Section 4) |
| `WhosDownDataCheck/` (Xcode project) | Small iOS app using the real Firebase SDK. **Models** tab decodes every sample document into the app structs. **Firestore** tab seeds the database and reads every collection back. **Weather** tab runs the Open-Meteo code from the playground inside the app. |
| `WhosDownDataCheck/WhosDownDataCheck/Models/Models.swift` | All app structs (Section 3) |
| `WhosDownDataCheck/WhosDownDataCheck/Data/SeedData.swift` | One or more sample records for every collection (Section 2) |
| `Screenshots/` | Proof that each piece runs (listed in each section) |
| Figma page **"05 — Sprint 3 Data Mapping"** | Marked-up hi-fi wireframes (Section 5) |

---

## 1. API Assessment

WhosDown does not need a custom API. All app data (games, RSVPs, profiles, groups, messages, reviews, notifications) is created by our own users, and Firebase gives us storage, real-time listeners, and authentication without running a server.

| Need | Service | Notes |
|---|---|---|
| Accounts and guest browsing | Firebase Authentication | Email/password; anonymous sign-in for guests |
| App data | Cloud Firestore | Schema in Section 2 |
| Photos and clips | Firebase Storage | `users/{uid}/avatar.jpg`, `games/{gameId}/media/{fileId}`, `groups/{groupId}/photo.jpg` |
| Push notifications | Firebase Cloud Messaging | Device tokens in `users/{uid}/private/settings.fcmTokens` |
| Map, place search, distance | Apple MapKit / Core Location | Replaces the Google Maps plan from Sprint 1; no key needed |
| Weather for outdoor games | Open-Meteo forecast API | Free, no API key (Section 4) |

**Rubric items that do not apply**

- **Internal API:** not applicable. We are not building our own server; Firebase covers it.
- **SwiftData (on-device store):** not applicable. All data lives in Firestore, which already caches data on the device for offline use.

---

## 2. Firebase JSON Structure

```
users/{userId}
    private/settings
    friends/{friendId}
    notifications/{notificationId}
venues/{venueId}
games/{gameId}
    rsvps/{userId}
groups/{groupId}
    members/{userId}
conversations/{conversationId}
    messages/{messageId}
reviews/{reviewId}
reports/{reportId}
```

In the examples below, Firestore `Timestamp` values are written as ISO date strings and `GeoPoint` values as `{latitude, longitude}`. Every example is a real record from `SeedData.swift`, which is what the screenshots show. Fields ending in `Lowercase` exist only so we can do prefix search (Firestore has no full-text search).

**users/{userId}:** a player's public profile.
```json
{
  "displayName": "Jamie Morales",
  "displayNameLowercase": "jamie morales",
  "photoURL": null,
  "bio": "Midfielder. I organize weeknight games and keep them welcoming but organized.",
  "homeArea": "Oakland / CMU",
  "schoolLine": "CMU '27",
  "position": "Midfielder",
  "isVerified": true,
  "isGuest": false,
  "playStyles": ["social", "competitive"],
  "sportLevels": { "soccer": "intermediate", "tennis": "casual" },
  "stats": {
    "gamesRSVPd": 32,
    "gamesAttended": 31,
    "gamesHosted": 14,
    "mvpCount": 2,
    "playAgainYes": 16,
    "playAgainTotal": 18,
    "feedbackTagCounts": { "reliable": 12, "goodSport": 9, "communicative": 7 },
    "recentFeedback": ["Clear communication and always shows up."],
    "avgResponseMinutes": 20
  },
  "createdAt": "2026-09-01T18:22:00Z"
}
```

**users/{userId}/private/settings:** readable only by the owner.
```json
{
  "email": "alex.morgan@example.com",
  "notificationPrefs": {
    "approvals": true, "timeOrLocationChanges": true, "cancellations": true,
    "reviewReminders": true, "newNearbyGames": false, "groupActivity": false, "messages": true
  },
  "newGameAlert": {
    "sports": ["soccer", "tennis"], "radiusMiles": 3.0,
    "weekdaysOnly": true, "earliestHour": 17, "skillLevels": ["allLevels"]
  },
  "privacy": {
    "gameActivity": "friends", "profileVisibility": "whosDownPlayers",
    "directMessages": "friendsAndTeammates", "friendRequests": "everyone"
  },
  "blockedUserIds": ["u_83jd"],
  "favoriteVenueIds": ["v_cmu_soccer", "v_schenley_oval"],
  "pinnedGroupIds": ["g_westside"],
  "searchRadiusMiles": 3.0,
  "fcmTokens": []
}
```

**users/{userId}/friends/{friendId}**
```json
{ "displayName": "Mina Kim", "status": "friends", "mutualCount": 4, "since": "2026-10-02T23:10:00Z" }
```

**users/{userId}/notifications/{notificationId}**
```json
{
  "type": "gameUpdated",
  "title": "Pickup Soccer changed location",
  "body": "Jamie: \"Lights are better on the lower turf.\"",
  "gameId": "gm_7d2k",
  "change": {
    "field": "location", "oldValue": "CMU Upper Turf", "newValue": "CMU Lower Turf",
    "hostNote": "Lights are better on the lower turf."
  },
  "isRead": false,
  "createdAt": "2026-10-28T22:41:00Z"
}
```

**venues/{venueId}**
```json
{
  "name": "CMU Soccer Field",
  "address": "5000 Forbes Ave, Pittsburgh, PA 15213",
  "location": { "latitude": 40.4433, "longitude": -79.9436 },
  "geohash": "dppnhf",
  "isIndoor": false,
  "surface": "turf",
  "hasLights": true,
  "sports": ["soccer", "football", "ultimate"],
  "createdBy": "u_jamie"
}
```

**games/{gameId}**
```json
{
  "title": "Pickup Soccer",
  "titleLowercase": "pickup soccer",
  "sport": "soccer",
  "customSportName": null,
  "description": "Friendly all-level pickup.",
  "notes": "Bring a light + dark shirt. Need 1 goalkeeper.",
  "hostId": "u_jamie",
  "hostName": "Jamie Morales",
  "groupId": null,
  "venueId": "v_cmu_soccer",
  "venueName": "CMU Soccer Field",
  "location": { "latitude": 40.4433, "longitude": -79.9436 },
  "geohash": "dppnhf",
  "isIndoor": false,
  "surface": "turf",
  "hasLights": true,
  "startTime": "2026-10-28T23:00:00Z",
  "endTime": "2026-10-29T00:30:00Z",
  "skillLevel": "allLevels",
  "visibility": "public",
  "joinType": "approvalRequired",
  "priceCents": 0,
  "playerLimit": 14,
  "waitlistEnabled": true,
  "joinedCount": 12,
  "pendingCount": 2,
  "waitlistCount": 0,
  "attendeePreview": ["AM", "MK", "JB", "TP", "CL", "RS"],
  "fieldReserved": true,
  "reservationWindow": "6:45–8:45 PM",
  "facilityNote": "No field conflict.",
  "mediaURLs": [],
  "status": "scheduled",
  "cancelReason": null,
  "conversationId": "c_gm_7d2k",
  "createdAt": "2026-10-24T15:02:00Z",
  "updatedAt": "2026-10-25T21:40:00Z"
}
```

**games/{gameId}/rsvps/{userId}**
```json
{
  "userId": "u_taylor",
  "displayName": "Taylor Ross",
  "reliability": 0.88,
  "skillLevel": "beginner",
  "status": "pending",
  "isHost": false,
  "noteToHost": "Happy to play defense or learn in goal.",
  "hostResponse": null,
  "waitlistPosition": null,
  "spotOfferExpiresAt": null,
  "attended": null,
  "personalNote": null,
  "requestedAt": "2026-10-25T20:15:00Z",
  "respondedAt": null
}
```

**groups/{groupId}**
```json
{
  "name": "West Side Pickup Crew",
  "nameLowercase": "west side pickup crew",
  "description": "Friendly weeknight soccer. Newcomers welcome.",
  "photoURL": null,
  "sports": ["soccer"],
  "localArea": "Oakland / CMU",
  "visibility": "public",
  "membershipType": "open",
  "ownerId": "u_jamie",
  "memberCount": 48,
  "conversationId": "c_grp_westside",
  "createdAt": "2026-09-10T00:00:00Z"
}
```

**groups/{groupId}/members/{userId}**
```json
{ "displayName": "Alex Morgan", "role": "member", "joinedAt": "2026-10-01T19:00:00Z" }
```

**conversations/{conversationId}:** one collection for direct, game, and group chats.
```json
{
  "type": "game",
  "title": "Pickup Soccer",
  "gameId": "gm_7d2k",
  "groupId": null,
  "participantIds": ["u_jamie", "u_alex", "u_mina"],
  "lastMessageText": "Thanks! Field is the lower turf now.",
  "lastMessageAt": "2026-10-28T22:24:00Z",
  "unreadCounts": { "u_alex": 0, "u_mina": 2 }
}
```

**conversations/{conversationId}/messages/{messageId}**
```json
{ "senderId": "u_mina", "senderName": "Mina Kim", "text": "Can someone bring an extra ball?", "mediaURL": null, "sentAt": "2026-10-28T22:12:00Z" }
```

**reviews/{reviewId}**
```json
{
  "gameId": "gm_7d2k",
  "reviewerId": "u_alex",
  "revieweeId": "u_jamie",
  "isMVP": true,
  "playAgain": true,
  "tags": ["reliable", "goodSport"],
  "comment": "Clear communication and made sure everyone was involved.",
  "createdAt": "2026-10-29T01:05:00Z"
}
```

**reports/{reportId}**
```json
{
  "reporterId": "u_alex",
  "reportedUserId": "u_83jd",
  "gameId": "gm_7d2k",
  "reason": "noShow",
  "details": "RSVP'd to three games and didn't come to any.",
  "status": "open",
  "createdAt": "2026-10-29T02:00:00Z"
}
```

**Seed data in Firestore.** The Firestore tab of `WhosDownDataCheck` writes all 23 sample documents (4 users, user settings, a friend, a notification, 2 venues, 2 games, 3 RSVPs, a group, 2 members, 2 conversations, 2 messages, a review, a report) in one batch, then reads every collection back with `document.data(as:)`.

The database is Firebase project `whosdown-57e99`.

> **Screenshots:** `Screenshots/03_firestore_console_games.jpg`, `_users.jpg`, `_rsvps.jpg`, `_messages.jpg` (Firebase console showing all seven top-level collections plus subcollections) and `Screenshots/04_firestore_readback.png` / `04b_firestore_readback_scrolled.png` (app reading every collection back: "Read 23 documents from 13 collections").

---

## 3. Swift Structs

Each struct matches one Firestore document above and decodes directly with `document.data(as:)`. The full code is in `Models.swift` and compiles against Firebase iOS SDK 13. `Timestamp` fields decode to `Date`, and `GeoPoint` is used as-is.

**Proof it works:** the **Models** tab of `WhosDownDataCheck` decodes all 23 sample documents (with real `Timestamp` and `GeoPoint` values) into these structs using `Firestore.Decoder`, the same decoder `data(as:)` uses. Result: **23 / 23 documents decoded**.

> **Screenshot:** `Screenshots/02_models_decoded.png`

```swift
import Foundation
import FirebaseFirestore

// MARK: - Shared enums

enum Sport: String, Codable, CaseIterable {
  case soccer, basketball, tennis, volleyball, pickleball, baseball, football, ultimate, other
}
enum SkillLevel: String, Codable, CaseIterable {
  case beginner, casual, allLevels, intermediate, competitive
}
enum PlayStyle: String, Codable, CaseIterable { case social, competitive, learning }
enum Visibility: String, Codable { case `public`, `private` }
enum JoinType: String, Codable { case open, approvalRequired }
enum GameStatus: String, Codable { case scheduled, cancelled, completed }
enum RSVPStatus: String, Codable { case pending, approved, declined, waitlisted, left, removed }
enum AudienceSetting: String, Codable { case everyone, whosDownPlayers, friendsAndTeammates, friends, nobody }
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

enum FriendStatus: String, Codable { case requestSent, requestReceived, friends }

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

enum MembershipType: String, Codable { case open, requestToJoin }

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

enum GroupRole: String, Codable { case owner, admin, member, pending }

struct GroupMember: Codable, Identifiable {
  @DocumentID var id: String?
  var displayName: String
  var role: GroupRole
  var joinedAt: Date
}

// MARK: - conversations/{conversationId}

enum ConversationType: String, Codable { case direct, game, group }

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

enum ReportReason: String, Codable { case harassment, noShow, misleadingEvent, other }
enum ReportStatus: String, Codable { case open, reviewing, resolved }

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
```

---

## 4. External API: Open-Meteo Weather

The weather line on Game Detail (H09), Joined Game (H14), and Venue & Details (H18) comes from Open-Meteo. It is free and needs no API key. `WhosDownWeather.playground` requests the forecast for a game's coordinates, decodes the JSON into Codable structs, and picks the hour closest to the game's start time. The same structs are used in the iOS app (`Models/Weather.swift`).

**Request**
```
GET https://api.open-meteo.com/v1/forecast?latitude=40.4433&longitude=-79.9436
    &hourly=temperature_2m,precipitation_probability,weather_code,wind_speed_10m
    &temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America/New_York&forecast_days=7
```

**Response (shortened; the full response has 168 hourly rows)**
```json
{
  "latitude": 40.4349,
  "longitude": -79.93617,
  "utc_offset_seconds": -14400,
  "timezone": "America/New_York",
  "hourly_units": { "temperature_2m": "°F", "wind_speed_10m": "mp/h" },
  "hourly": {
    "time": ["2026-10-25T00:00", "2026-10-25T01:00"],
    "temperature_2m": [46.9, 44.9],
    "precipitation_probability": [0, 0],
    "weather_code": [0, 0],
    "wind_speed_10m": [4.8, 2.9]
  }
}
```

**Structs**
```swift
struct ForecastResponse: Decodable {
  let latitude: Double
  let longitude: Double
  let timezone: String
  let utcOffsetSeconds: Int
  let hourlyUnits: HourlyUnits
  let hourly: Hourly

  enum CodingKeys: String, CodingKey {
    case latitude, longitude, timezone
    case utcOffsetSeconds = "utc_offset_seconds"
    case hourlyUnits = "hourly_units"
    case hourly
  }
}

struct HourlyUnits: Decodable {
  let temperature: String
  let windSpeed: String

  enum CodingKeys: String, CodingKey {
    case temperature = "temperature_2m"
    case windSpeed = "wind_speed_10m"
  }
}

// Parallel arrays: index i of every array is the same hour.
struct Hourly: Decodable {
  let time: [String]
  let temperature: [Double]
  let precipitationProbability: [Int]
  let weatherCode: [Int]
  let windSpeed: [Double]

  enum CodingKeys: String, CodingKey {
    case time
    case temperature = "temperature_2m"
    case precipitationProbability = "precipitation_probability"
    case weatherCode = "weather_code"
    case windSpeed = "wind_speed_10m"
  }
}

// What the interface reads: one value per hour.
struct HourlyForecast {
  let date: Date
  let temperatureF: Double
  let precipitationProbability: Int
  let weatherCode: Int
  let windSpeedMph: Double

  var conditionText: String { /* WMO code → "Clear", "Partly cloudy", "Rain", … */ }
  var summaryLine: String { "\(Int(temperatureF.rounded()))°F · \(conditionText) · \(precipitationProbability)% rain" }
}
```

`ForecastResponse.hours` turns the parallel arrays into `[HourlyForecast]`, applying `utc_offset_seconds` because Open-Meteo returns local times without an offset. `forecast(closestTo: game.startTime)` returns the hour shown on the screen.

**Playground output** (run on Oct 25, 2026)
```
WhosDown weather check — Open-Meteo
==================================
Pickup Soccer @ CMU Soccer Field
  Start:  Mon Oct 26, 7:00 PM
  Decoded 168 hourly rows for (40.4349, -79.93617), America/New_York
  Hour:   Mon Oct 26, 7:00 PM
  60°F · Overcast · 1% rain · Outdoor
  Wind 1 mph
7v7 at Schenley @ Schenley Oval
  Start:  Mon Oct 26, 8:15 PM
  Decoded 168 hourly rows for (40.4349, -79.93617), America/New_York
  Hour:   Mon Oct 26, 8:00 PM
  57°F · Overcast · 1% rain · Outdoor
  Wind 3 mph
Done.
```
The playground always asks for the next 7:00 PM and 8:15 PM, so it works whenever it is run. Weather values change with the live forecast.

> **Screenshots:** `Screenshots/05_playground_output.webp` (playground run in Xcode, console showing the output above) and `Screenshots/01_weather_open_meteo.png` (same code in the iOS app, using the two seeded games' locations and start times: Pickup Soccer, Oct 28 7:00 PM → 61°F · Overcast · 0% rain).

---

## 5. Wireframe Data Mapping

The marked-up wireframes are in the Figma file on page **"05 — Sprint 3 Data Mapping"**. All 63 hi-fi screens (H01–H63) are copied there. On each copy, every piece of data has a numbered, color-coded badge, and a panel beside the screen gives its source and the struct property that holds it.

| Color | Source |
|---|---|
| Blue | Cloud Firestore |
| Purple | Firebase Auth |
| Teal | Firebase Storage |
| Orange | Open-Meteo API |
| Green | MapKit / Core Location |
| Pink | User input, written to Firestore |
| Gray | Computed on the device |

The same mapping is also written out as tables, screen by screen, in `Sprint3_Section5_DataMapping.md`.

---

## 6. List of Features

See `Sprint3_Section6_Features.md`.
