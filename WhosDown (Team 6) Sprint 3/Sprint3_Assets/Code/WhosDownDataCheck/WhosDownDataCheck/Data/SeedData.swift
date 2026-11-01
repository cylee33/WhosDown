import Foundation
import FirebaseCore
import FirebaseFirestore

// Sample documents for every collection in the WhosDown Firestore schema.
// The same dictionaries are (1) decoded offline into the app structs on the
// Models tab and (2) written to Firestore by the Seed button on the Firestore tab.

struct SeedDocument {
  let path: String
  let data: [String: Any]
  // Decodes `data` into its app struct and returns a one-line summary.
  let check: ([String: Any], DocumentReference) throws -> String

  func runCheck() throws -> String {
    try check(data, SeedData.offlineDB.document(path))
  }
}

private func ts(_ iso: String) -> Timestamp {
  Timestamp(date: ISO8601DateFormatter().date(from: iso)!)
}

// @DocumentID needs the document's reference to decode, so the offline
// check passes one in, the same way document.data(as:) does.
func decode<T: Decodable>(_ type: T.Type, _ data: [String: Any], _ reference: DocumentReference) throws -> T {
  try Firestore.Decoder().decode(T.self, from: data, in: reference)
}

enum SeedData {
  // A local-only Firebase app used to build DocumentReferences for the
  // offline decode check. It never connects to a server.
  static let offlineDB: Firestore = {
    if FirebaseApp.app(name: "offline") == nil {
      let options = FirebaseOptions(googleAppID: "1:000000000000:ios:0000000000000000", gcmSenderID: "000000000000")
      options.projectID = "whosdown-offline"
      options.apiKey = "offline"
      FirebaseApp.configure(name: "offline", options: options)
    }
    return Firestore.firestore(app: FirebaseApp.app(name: "offline")!)
  }()

  static let cmuField = GeoPoint(latitude: 40.4433, longitude: -79.9436)
  static let schenleyOval = GeoPoint(latitude: 40.4339, longitude: -79.9406)

  static let documents: [SeedDocument] = [
    // MARK: users
    SeedDocument(path: "users/u_jamie", data: [
      "displayName": "Jamie Morales",
      "displayNameLowercase": "jamie morales",
      "photoURL": NSNull(),
      "bio": "Midfielder. I organize weeknight games and keep them welcoming but organized.",
      "homeArea": "Oakland / CMU",
      "schoolLine": "CMU '27",
      "position": "Midfielder",
      "isVerified": true,
      "isGuest": false,
      "playStyles": ["social", "competitive"],
      "sportLevels": ["soccer": "intermediate", "tennis": "casual"],
      "stats": [
        "gamesRSVPd": 32, "gamesAttended": 31, "gamesHosted": 14, "mvpCount": 2,
        "playAgainYes": 16, "playAgainTotal": 18,
        "feedbackTagCounts": ["reliable": 12, "goodSport": 9, "communicative": 7],
        "recentFeedback": ["Clear communication and always shows up."],
        "avgResponseMinutes": 20
      ],
      "createdAt": ts("2026-09-01T18:22:00Z")
    ], check: { d, ref in
      let u = try decode(AppUser.self, d, ref)
      return "\(u.displayName) (\(u.initials)) · \(Int((u.stats.reliability ?? 0) * 100))% reliable"
    }),
    SeedDocument(path: "users/u_alex", data: [
      "displayName": "Alex Morgan",
      "displayNameLowercase": "alex morgan",
      "photoURL": NSNull(),
      "bio": "Midfielder who likes quick passing and friendly competitive games.",
      "homeArea": "Oakland / CMU",
      "schoolLine": "CMU '28",
      "position": "Midfielder",
      "isVerified": false,
      "isGuest": false,
      "playStyles": ["social"],
      "sportLevels": ["soccer": "allLevels", "tennis": "casual"],
      "stats": [
        "gamesRSVPd": 18, "gamesAttended": 17, "gamesHosted": 0, "mvpCount": 1,
        "playAgainYes": 9, "playAgainTotal": 10,
        "feedbackTagCounts": ["reliable": 5, "goodSport": 4],
        "recentFeedback": ["Easy to play with and responds quickly."]
      ],
      "createdAt": ts("2026-09-03T14:00:00Z")
    ], check: { d, ref in
      let u = try decode(AppUser.self, d, ref)
      return "\(u.displayName) · \(u.stats.gamesAttended)/\(u.stats.gamesRSVPd) attended"
    }),
    SeedDocument(path: "users/u_mina", data: [
      "displayName": "Mina Kim",
      "displayNameLowercase": "mina kim",
      "bio": "Weekend soccer and tennis.",
      "homeArea": "Shadyside",
      "position": "Midfielder",
      "isVerified": true,
      "isGuest": false,
      "playStyles": ["social", "learning"],
      "sportLevels": ["soccer": "allLevels", "tennis": "intermediate"],
      "stats": [
        "gamesRSVPd": 16, "gamesAttended": 15, "gamesHosted": 2, "mvpCount": 0,
        "playAgainYes": 8, "playAgainTotal": 8,
        "feedbackTagCounts": ["welcoming": 6], "recentFeedback": []
      ],
      "createdAt": ts("2026-09-05T20:10:00Z")
    ], check: { d, ref in
      let u = try decode(AppUser.self, d, ref)
      return "\(u.displayName) · \(u.sportLevels.count) sports"
    }),
    SeedDocument(path: "users/u_taylor", data: [
      "displayName": "Taylor Ross",
      "displayNameLowercase": "taylor ross",
      "bio": "Learning soccer this semester.",
      "homeArea": "Squirrel Hill",
      "position": "Forward",
      "isVerified": false,
      "isGuest": false,
      "playStyles": ["learning"],
      "sportLevels": ["soccer": "beginner"],
      "stats": [
        "gamesRSVPd": 8, "gamesAttended": 7, "gamesHosted": 0, "mvpCount": 0,
        "playAgainYes": 3, "playAgainTotal": 4,
        "feedbackTagCounts": [:], "recentFeedback": []
      ],
      "createdAt": ts("2026-09-20T16:45:00Z")
    ], check: { d, ref in
      let u = try decode(AppUser.self, d, ref)
      return "\(u.displayName) · \(u.sportLevels["soccer"]?.rawValue ?? "-")"
    }),

    // MARK: users/u_alex subcollections
    SeedDocument(path: "users/u_alex/private/settings", data: [
      "email": "alex.morgan@example.com",
      "notificationPrefs": [
        "approvals": true, "timeOrLocationChanges": true, "cancellations": true,
        "reviewReminders": true, "newNearbyGames": false, "groupActivity": false, "messages": true
      ],
      "newGameAlert": [
        "sports": ["soccer", "tennis"], "radiusMiles": 3.0,
        "weekdaysOnly": true, "earliestHour": 17, "skillLevels": ["allLevels"]
      ],
      "privacy": [
        "gameActivity": "friends", "profileVisibility": "whosDownPlayers",
        "directMessages": "friendsAndTeammates", "friendRequests": "everyone"
      ],
      "blockedUserIds": ["u_83jd"],
      "favoriteVenueIds": ["v_cmu_soccer", "v_schenley_oval"],
      "pinnedGroupIds": ["g_westside"],
      "searchRadiusMiles": 3.0,
      "fcmTokens": []
    ], check: { d, ref in
      let s = try decode(UserSettings.self, d, ref)
      return "radius \(s.searchRadiusMiles) mi · alert \(s.newGameAlert?.sports.map(\.rawValue).joined(separator: "+") ?? "off")"
    }),
    SeedDocument(path: "users/u_alex/friends/u_mina", data: [
      "displayName": "Mina Kim", "status": "friends", "mutualCount": 4,
      "since": ts("2026-10-02T23:10:00Z")
    ], check: { d, ref in
      let f = try decode(Friendship.self, d, ref)
      return "\(f.displayName) · \(f.status.rawValue) · \(f.mutualCount) mutual"
    }),
    SeedDocument(path: "users/u_alex/notifications/n_location", data: [
      "type": "gameUpdated",
      "title": "Pickup Soccer changed location",
      "body": "Jamie: \"Lights are better on the lower turf.\"",
      "gameId": "gm_7d2k",
      "change": [
        "field": "location", "oldValue": "CMU Upper Turf", "newValue": "CMU Lower Turf",
        "hostNote": "Lights are better on the lower turf."
      ],
      "isRead": false,
      "createdAt": ts("2026-10-28T22:41:00Z")
    ], check: { d, ref in
      let n = try decode(AppNotification.self, d, ref)
      return "\(n.type.rawValue): \(n.change?.oldValue ?? "") → \(n.change?.newValue ?? "")"
    }),

    // MARK: venues
    SeedDocument(path: "venues/v_cmu_soccer", data: [
      "name": "CMU Soccer Field",
      "address": "5000 Forbes Ave, Pittsburgh, PA 15213",
      "location": cmuField,
      "geohash": "dppnhf",
      "isIndoor": false,
      "surface": "turf",
      "hasLights": true,
      "sports": ["soccer", "football", "ultimate"],
      "createdBy": "u_jamie"
    ], check: { d, ref in
      let v = try decode(Venue.self, d, ref)
      return "\(v.name) · (\(v.location.latitude), \(v.location.longitude))"
    }),
    SeedDocument(path: "venues/v_schenley_oval", data: [
      "name": "Schenley Oval",
      "address": "Overlook Dr, Pittsburgh, PA 15213",
      "location": schenleyOval,
      "geohash": "dppnh9",
      "isIndoor": false,
      "surface": "grass",
      "hasLights": false,
      "sports": ["soccer", "ultimate", "football"],
      "createdBy": "u_mina"
    ], check: { d, ref in
      let v = try decode(Venue.self, d, ref)
      return "\(v.name) · \(v.surface ?? "-")"
    }),

    // MARK: games
    SeedDocument(path: "games/gm_7d2k", data: [
      "title": "Pickup Soccer",
      "titleLowercase": "pickup soccer",
      "sport": "soccer",
      "description": "Friendly all-level pickup.",
      "notes": "Bring a light + dark shirt. Need 1 goalkeeper.",
      "hostId": "u_jamie",
      "hostName": "Jamie Morales",
      "venueId": "v_cmu_soccer",
      "venueName": "CMU Soccer Field",
      "location": cmuField,
      "geohash": "dppnhf",
      "isIndoor": false,
      "surface": "turf",
      "hasLights": true,
      "startTime": ts("2026-10-28T23:00:00Z"),
      "endTime": ts("2026-10-29T00:30:00Z"),
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
      "conversationId": "c_gm_7d2k",
      "createdAt": ts("2026-10-24T15:02:00Z"),
      "updatedAt": ts("2026-10-25T21:40:00Z")
    ], check: { d, ref in
      let g = try decode(Game.self, d, ref)
      return "\(g.title) · \(g.joinedCount)/\(g.playerLimit) · \(g.spotsLeft) left · \(g.isFree ? "Free" : "Paid")"
    }),
    SeedDocument(path: "games/gm_schenley", data: [
      "title": "7v7 at Schenley",
      "titleLowercase": "7v7 at schenley",
      "sport": "soccer",
      "description": "Intermediate 7v7, bring cleats.",
      "hostId": "u_mina",
      "hostName": "Mina Kim",
      "groupId": "g_westside",
      "venueId": "v_schenley_oval",
      "venueName": "Schenley Oval",
      "location": schenleyOval,
      "geohash": "dppnh9",
      "isIndoor": false,
      "surface": "grass",
      "hasLights": false,
      "startTime": ts("2026-10-31T00:15:00Z"),
      "endTime": ts("2026-10-31T01:45:00Z"),
      "skillLevel": "intermediate",
      "visibility": "public",
      "joinType": "open",
      "priceCents": 500,
      "playerLimit": 14,
      "waitlistEnabled": true,
      "joinedCount": 9,
      "pendingCount": 0,
      "waitlistCount": 0,
      "attendeePreview": ["MK", "CP", "DC"],
      "fieldReserved": false,
      "mediaURLs": [],
      "status": "scheduled",
      "conversationId": "c_gm_schenley",
      "createdAt": ts("2026-10-25T12:00:00Z"),
      "updatedAt": ts("2026-10-25T12:00:00Z")
    ], check: { d, ref in
      let g = try decode(Game.self, d, ref)
      return "\(g.title) · $\(g.priceCents / 100) · \(g.joinType.rawValue)"
    }),

    // MARK: games/gm_7d2k/rsvps
    SeedDocument(path: "games/gm_7d2k/rsvps/u_jamie", data: [
      "userId": "u_jamie", "displayName": "Jamie Morales", "reliability": 0.96,
      "skillLevel": "intermediate", "status": "approved", "isHost": true,
      "requestedAt": ts("2026-10-24T15:02:00Z"), "respondedAt": ts("2026-10-24T15:02:00Z")
    ], check: { d, ref in
      let r = try decode(RSVP.self, d, ref)
      return "\(r.displayName) · \(r.status.rawValue)\(r.isHost ? " · host" : "")"
    }),
    SeedDocument(path: "games/gm_7d2k/rsvps/u_alex", data: [
      "userId": "u_alex", "displayName": "Alex Morgan", "reliability": 0.94,
      "skillLevel": "allLevels", "status": "approved", "isHost": false,
      "noteToHost": "I'm new to this group — happy to play anywhere.",
      "requestedAt": ts("2026-10-25T18:00:00Z"), "respondedAt": ts("2026-10-25T18:20:00Z")
    ], check: { d, ref in
      let r = try decode(RSVP.self, d, ref)
      return "\(r.displayName) · \(r.status.rawValue)"
    }),
    SeedDocument(path: "games/gm_7d2k/rsvps/u_taylor", data: [
      "userId": "u_taylor", "displayName": "Taylor Ross", "reliability": 0.88,
      "skillLevel": "beginner", "status": "pending", "isHost": false,
      "noteToHost": "Happy to play defense or learn in goal.",
      "requestedAt": ts("2026-10-25T20:15:00Z")
    ], check: { d, ref in
      let r = try decode(RSVP.self, d, ref)
      return "\(r.displayName) · \(r.status.rawValue) · “\(r.noteToHost ?? "")”"
    }),

    // MARK: groups
    SeedDocument(path: "groups/g_westside", data: [
      "name": "West Side Pickup Crew",
      "nameLowercase": "west side pickup crew",
      "description": "Friendly weeknight soccer. Newcomers welcome.",
      "sports": ["soccer"],
      "localArea": "Oakland / CMU",
      "visibility": "public",
      "membershipType": "open",
      "ownerId": "u_jamie",
      "memberCount": 48,
      "conversationId": "c_grp_westside",
      "createdAt": ts("2026-09-10T00:00:00Z")
    ], check: { d, ref in
      let g = try decode(PlayGroup.self, d, ref)
      return "\(g.name) · \(g.memberCount) members"
    }),
    SeedDocument(path: "groups/g_westside/members/u_jamie", data: [
      "displayName": "Jamie Morales", "role": "owner", "joinedAt": ts("2026-09-10T00:00:00Z")
    ], check: { d, ref in
      let m = try decode(GroupMember.self, d, ref)
      return "\(m.displayName) · \(m.role.rawValue)"
    }),
    SeedDocument(path: "groups/g_westside/members/u_alex", data: [
      "displayName": "Alex Morgan", "role": "member", "joinedAt": ts("2026-10-01T19:00:00Z")
    ], check: { d, ref in
      let m = try decode(GroupMember.self, d, ref)
      return "\(m.displayName) · \(m.role.rawValue)"
    }),

    // MARK: conversations
    SeedDocument(path: "conversations/c_gm_7d2k", data: [
      "type": "game",
      "title": "Pickup Soccer",
      "gameId": "gm_7d2k",
      "participantIds": ["u_jamie", "u_alex", "u_mina"],
      "lastMessageText": "Thanks! Field is the lower turf now.",
      "lastMessageAt": ts("2026-10-28T22:24:00Z"),
      "unreadCounts": ["u_alex": 0, "u_mina": 2]
    ], check: { d, ref in
      let c = try decode(Conversation.self, d, ref)
      return "\(c.type.rawValue) · \(c.title) · \(c.participantIds.count) people"
    }),
    SeedDocument(path: "conversations/c_gm_7d2k/messages/m_1", data: [
      "senderId": "u_mina", "senderName": "Mina Kim",
      "text": "Can someone bring an extra ball?", "sentAt": ts("2026-10-28T22:12:00Z")
    ], check: { d, ref in
      let m = try decode(Message.self, d, ref)
      return "\(m.senderName): \(m.text)"
    }),
    SeedDocument(path: "conversations/c_gm_7d2k/messages/m_2", data: [
      "senderId": "u_jamie", "senderName": "Jamie Morales",
      "text": "Thanks! Field is the lower turf now.", "sentAt": ts("2026-10-28T22:24:00Z")
    ], check: { d, ref in
      let m = try decode(Message.self, d, ref)
      return "\(m.senderName): \(m.text)"
    }),
    SeedDocument(path: "conversations/c_dm_alex_mina", data: [
      "type": "direct",
      "title": "Mina Kim",
      "participantIds": ["u_alex", "u_mina"],
      "lastMessageText": "Are you free for 7v7 Friday?",
      "lastMessageAt": ts("2026-10-25T22:30:00Z"),
      "unreadCounts": ["u_alex": 2, "u_mina": 0]
    ], check: { d, ref in
      let c = try decode(Conversation.self, d, ref)
      return "\(c.type.rawValue) · \(c.lastMessageText ?? "")"
    }),

    // MARK: reviews
    SeedDocument(path: "reviews/r_alex_jamie", data: [
      "gameId": "gm_7d2k",
      "reviewerId": "u_alex",
      "revieweeId": "u_jamie",
      "isMVP": true,
      "playAgain": true,
      "tags": ["reliable", "goodSport"],
      "comment": "Clear communication and made sure everyone was involved.",
      "createdAt": ts("2026-10-29T01:05:00Z")
    ], check: { d, ref in
      let r = try decode(Review.self, d, ref)
      return "MVP \(r.isMVP) · play again \(r.playAgain) · \(r.tags.map(\.rawValue).joined(separator: ", "))"
    }),

    // MARK: reports
    SeedDocument(path: "reports/rp_1", data: [
      "reporterId": "u_alex",
      "reportedUserId": "u_83jd",
      "gameId": "gm_7d2k",
      "reason": "noShow",
      "details": "RSVP'd to three games and didn't come to any.",
      "status": "open",
      "createdAt": ts("2026-10-29T02:00:00Z")
    ], check: { d, ref in
      let r = try decode(Report.self, d, ref)
      return "\(r.reason.rawValue) · \(r.status.rawValue)"
    })
  ]
}
