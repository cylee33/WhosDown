# 5. Wireframe Data Mapping

This section maps every piece of data on the 63 high-fidelity screens (H01–H63, Figma page "03 — Hi-Fi Full Marks") to where it comes from and which Swift struct property holds it. Static copy (headings, helper text, button labels) is not listed.

**Source key**

| Tag | Meaning |
|---|---|
| **FS** | Cloud Firestore document or query (path shown) |
| **Auth** | Firebase Authentication (`Auth.auth().currentUser`) |
| **Storage** | Firebase Storage (photos and clips; download URL saved in Firestore) |
| **FCM** | Firebase Cloud Messaging push |
| **OM** | Open-Meteo forecast API (Section 4) |
| **MK** | Apple MapKit / Core Location (map, place search, user location, distance) |
| **Input** | Entered by the user on this screen, then written to the FS path shown |
| **Computed** | Derived on device from the fields listed |
| **Local** | View state only, not stored |

Firebase Storage paths: `users/{userId}/avatar.jpg`, `games/{gameId}/media/{fileId}`, `groups/{groupId}/photo.jpg`.

Common queries used across screens:

- **Nearby games:** `games` where `geohash` in the geohash ranges covering the search radius, `status == "scheduled"`, `startTime >= now`, then filtered on device by exact distance (MK) and the active filters.
- **My RSVPs:** collection group `rsvps` where `userId == me`, then the parent `games` documents fetched by ID.
- **Friends:** `users/{me}/friends` where `status == "friends"`.
- **Distance:** `CLLocation(user).distance(from: game.location)`, shown in miles.
- **Weather line:** OM request with `game.location` and the hour closest to `game.startTime` (`temperature_2m`, `weather_code` → text, `precipitation_probability`). Shown only when `game.isIndoor == false`.

---

## A — Onboarding & Personalization

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H01 Welcome | Create account / Sign in | Auth | — |
| | Explore as guest | Auth (anonymous sign-in) + FS `users/{uid}` | `AppUser.isGuest = true` |
| H02 Create Account | Email | Input → Auth + FS `users/{uid}/private/settings` | `UserSettings.email` |
| | Password | Input → Auth only (never stored in FS) | — |
| | Display name | Input → FS `users/{uid}` | `AppUser.displayName` |
| H03 Select Sports | Sport chips (Soccer … Other) | Input → FS `users/{uid}` | keys of `AppUser.sportLevels` (`Sport`) |
| H42 Skill Levels | Level per selected sport | Input → FS `users/{uid}` | `AppUser.sportLevels[sport]` (`SkillLevel`) |
| H04 Complete Profile | Photo / initials "AM" | Input → Storage; else Computed | `AppUser.photoURL`, `AppUser.initials` |
| | Play style | Input → FS `users/{uid}` | `AppUser.playStyles` |
| | Soccer level | Input → FS `users/{uid}` | `AppUser.sportLevels["soccer"]` |
| | Bio, Home area | Input → FS `users/{uid}` | `AppUser.bio`, `AppUser.homeArea` |
| H05 Permissions | Location permission | MK (`CLLocationManager.requestWhenInUseAuthorization`) | — (device setting) |
| | Approvals / Time-location / Cancellations toggles | Input → FS `users/{uid}/private/settings` | `NotificationPrefs.approvals`, `.timeOrLocationChanges`, `.cancellations` |
| H43 Notification Permission | Enable notifications | `UNUserNotificationCenter` + FCM token → FS `private/settings` | `UserSettings.fcmTokens` |
| H44 Onboarding Complete | "Soccer + Tennis · Oakland/CMU · All Levels · Important notifications" | FS `users/{uid}` + `private/settings` | `AppUser.sportLevels`, `AppUser.homeArea`, `NotificationPrefs` |
| H41 Sign In | Email, password | Input → Auth (`signIn(withEmail:password:)`) | — |
| | Forgot password | Auth (`sendPasswordReset`) | — |

## B — Discover, Filter & Trust

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H06 Discover Map | Map, user location, radius circle | MK (`Map`, `MapCircle`) | `UserSettings.searchRadiusMiles` |
| | Sport pins (S/B/T/S/P) | FS nearby games | `Game.location`, `Game.sport` |
| | "NEXT UP · Pickup Soccer · 7:00 PM · CMU Soccer Field · Approved ✓" | FS My RSVPs, first upcoming with `status == approved` | `RSVP.status`, `Game.title`, `.startTime`, `.venueName` |
| | Filter chips (Soccer · Today · ≤ 3 mi · Any level) | Local (filter state) | — |
| | Pin card: title, time, distance, level, 12/14, Free | FS `games/{id}` + MK distance | `Game.title`, `.startTime`, `.skillLevel`, `.joinedCount`, `.playerLimit`, `.isFree` |
| H07 Discover List | Each row: title, time, venue, distance, level, count, price ($5) | FS nearby games + MK distance | `Game.title`, `.startTime`, `.venueName`, `.skillLevel`, `.joinedCount`/`.playerLimit`, `.priceCents` |
| | "Filters 2" badge | Local | — |
| | "Why these? Based on Soccer + Tennis, distance, and your play style" | Computed | `AppUser.sportLevels`, `AppUser.playStyles`, distance |
| H08 Filters Sheet | Sport, Time, Distance, Skill, Join type | Local; distance also saved → FS `private/settings` | `UserSettings.searchRadiusMiles`; filters on `Game.sport`, `.startTime`, `.skillLevel`, `.joinType`, `.waitlistEnabled` |
| | "Alert me when a matching game is posted" | Input → FS `private/settings` | `UserSettings.newGameAlert` (`NewGameAlertRule`) |
| | "Show 6 games" | Computed (count of filtered results) | — |
| H09 Game Detail | Media "2 photos · 1 clip" | Storage URLs in FS `games/{id}` | `Game.mediaURLs` |
| | Title, PUBLIC / FREE / APPROVAL / ALL LEVELS badges | FS `games/{id}` | `Game.title`, `.visibility`, `.isFree`, `.joinType`, `.skillLevel` |
| | "Today · 7:00–8:30 PM" | FS `games/{id}` | `Game.startTime`, `.endTime` |
| | "CMU Soccer Field · 0.4 mi" | FS + MK distance | `Game.venueName`, `.location` |
| | "64°F · Clear · Outdoor" | OM + FS | `HourlyForecast` (Section 4), `Game.isIndoor` |
| | "Turf · Lights on · Field reserved 6:45–8:45", facility note | FS `games/{id}` | `Game.surface`, `.hasLights`, `.fieldReserved`, `.reservationWindow`, `.facilityNote` |
| | "12 / 14 joined · 2 spots left" | FS `games/{id}` | `Game.joinedCount`, `.playerLimit`, `.spotsLeft` |
| | Avatar row "AM MK … +6" | FS `games/{id}` | `Game.attendeePreview` |
| | "2 friends attending" | Computed: FS `games/{id}/rsvps` (approved) ∩ Friends | `RSVP.userId`, `Friendship.id` |
| | Organizer "Jamie · 96% attendance · Great communicator" | FS `users/{hostId}` | `Game.hostName`, `PlayerStats.reliability`, top of `PlayerStats.feedbackTagCounts` |
| | "Host usually responds within 20 min" | FS `users/{hostId}.stats.avgResponseMinutes` (updated when host approves/declines) | `PlayerStats.avgResponseMinutes`  |
| | Request to join | Opens H12 (or H34 if `AppUser.isGuest`, H15 if `Game.isFull`) | — |
| H10 Organizer Profile | Initials, name, Verified | FS `users/{id}` | `AppUser.initials`, `.displayName`, `.isVerified` |
| | "CMU '27 · Soccer Intermediate · 34 games" | FS `users/{id}` | `AppUser.schoolLine`, `.sportLevels`, `PlayerStats.gamesAttended + gamesHosted` |
| | Reliability "96% · 31 / 32 games attended" | FS `users/{id}` | `PlayerStats.reliability`, `.gamesAttended`, `.gamesRSVPd` |
| | Play style chips | FS `users/{id}` | `AppUser.playStyles`, top `PlayerStats.feedbackTagCounts` |
| | Bio, recent feedback quote | FS `users/{id}` | `AppUser.bio`, `PlayerStats.recentFeedback` |
| | Add friend | Input → FS `users/{me}/friends/{id}` (`requestSent`) and `users/{id}/friends/{me}` (`requestReceived`) | `Friendship.status` |
| | Message | FS `conversations` where `type == direct` and both IDs in `participantIds`; create if none | `Conversation` |
| | Safety & reporting | Opens H33 | — |

## C — Joining, Coordination & Host Control

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H11 Player Roster | Header "Pickup Soccer · Today 7:00 PM · 12 / 14 joined · 2 friends" | FS `games/{id}` + Computed friends | `Game.title`, `.startTime`, `.joinedCount`, `.playerLimit` |
| | Each player: initials, name, "Organizer", reliability %, level | FS `games/{id}/rsvps` where `status == approved` | `RSVP.displayName`, `.isHost`, `.reliability`, `.skillLevel` |
| | "Friend · Midfielder" | Computed (Friends) + FS `users/{userId}` | `Friendship`, `AppUser.position` |
| | "New player · 2 games" | FS `users/{userId}` (`reliability == nil` or few games) | `PlayerStats.gamesAttended` |
| | Invite a friend | Input → FS `users/{friendId}/notifications` (type `newGame`) | `AppNotification` |
| H12 Join Review | Title, time, venue, badges | FS `games/{id}` | `Game.*` (as H09) |
| | "You won't be charged · This game is free" | FS | `Game.priceCents` |
| | "You'll see Pending until Jamie approves you" | FS | `Game.joinType`, `Game.hostName` |
| | Note to host | Input → FS `games/{id}/rsvps/{me}` | `RSVP.noteToHost` |
| | Send join request | Input → FS `rsvps/{me}` (`status: pending`), `games/{id}.pendingCount += 1` | `RSVP.status`, `.requestedAt`, `Game.pendingCount` |
| H13 Pending Approval | PENDING badge | FS `games/{id}/rsvps/{me}` (live listener) | `RSVP.status` |
| | Game summary, "12 / 14 players", "Approval required" | FS `games/{id}` | `Game.*` |
| | Cancel request | Input → FS `rsvps/{me}.status = left`, `pendingCount -= 1` | `RSVP.status` |
| H14 Joined Game | APPROVED ✓ | FS `rsvps/{me}` | `RSVP.status` |
| | Host note "Bring a light + dark shirt…" | FS `games/{id}` | `Game.notes` |
| | Chat | Opens H16 | `Game.conversationId` |
| | Invite friend | as H11 | — |
| | Calendar | EventKit (device), from FS | `Game.title`, `.startTime`, `.endTime`, `.venueName` |
| | "Outdoor turf · Lights on · 64°F Clear" | FS + OM | `Game.isIndoor`, `.surface`, `.hasLights`, `HourlyForecast` |
| | "Field reserved · no known conflicts" | FS | `Game.fieldReserved`, `.facilityNote` |
| | Leave game | Opens H37 | — |
| H15 Full / Waitlist | FULL, "14 / 14 players" | FS `games/{id}` | `Game.isFull`, `.joinedCount`, `.playerLimit` |
| | "Waitlist is enabled", "2 people waiting" | FS `games/{id}` | `Game.waitlistEnabled`, `.waitlistCount` |
| | Join waitlist → "WAITLISTED · Position #3" | Input → FS `rsvps/{me}` (`status: waitlisted`), `waitlistCount += 1` | `RSVP.status`, `RSVP.waitlistPosition` |
| | Find similar games | FS nearby games, same `sport` and `skillLevel` | `Game` |
| H16 Event Chat | Title, "Game chat · 12 players" | FS `conversations/{id}` | `Conversation.title`, `.participantIds.count` |
| | Messages: sender initials, text, time | FS `conversations/{id}/messages` ordered by `sentAt` (live listener) | `Message.senderName`, `.text`, `.sentAt` |
| | Own vs other bubble | Computed | `Message.senderId == me` |
| | Message input | Input → FS `messages` + update `lastMessageText`, `lastMessageAt`, `unreadCounts` | `Message`, `Conversation` |
| | ＋ attach | Storage (V2), URL saved in `messages` | `Message.mediaURL`  |

## D — Create & Manage

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H17 Create Activity | Sport | Input | `Game.sport` |
| | "+ Add custom activity" | Input — `customSportName: String?` to `games` when `sport == other` | `Game.customSportName`  |
| | Date & time | Input | `Game.startTime`, `.endTime` |
| | Location | Opens H40 | `Game.venueId`, `.venueName`, `.location`, `.geohash` |
| | Skill, Player limit, Join type, Visibility, Price | Input | `Game.skillLevel`, `.playerLimit`, `.joinType`, `.visibility`, `.priceCents` |
| H40 Choose Location | Search field, park, or address | MK `MKLocalSearch` + FS `venues` by geohash and name | `Venue` |
| | Map pins | MK + FS `venues` | `Venue.location`, `Venue.sports` |
| | "CMU Field · 0.4 mi · Outdoor turf · Lights" | FS `venues/{id}` + MK distance | `Venue.name`, `.isIndoor`, `.surface`, `.hasLights` |
| | Suggested list | FS favorite venues first, then nearby | `UserSettings.favoriteVenueIds`, `Venue` |
| | New place from MapKit | Input → FS new `venues/{id}` | `Venue.createdBy` |
| H18 Venue & Details | Venue name, Outdoor, Turf, Lights | FS `venues/{id}`, copied into game | `Venue.*` → `Game.isIndoor`, `.surface`, `.hasLights` |
| | "Reserved 6:45–8:45 PM" | Input | `Game.fieldReserved`, `.reservationWindow` |
| | Facility note | Input | `Game.facilityNote` |
| | "64°F · Clear · 8% rain · Outdoor event" | OM | `HourlyForecast.temperature`, `.weatherCode`, `.precipitationProbability` |
| | Add photo / Add clip | Input → Storage `games/{id}/media/` | `Game.mediaURLs` |
| | Notes | Input | `Game.notes` |
| H19 Review & Publish | Summary of all fields from H17–H18 | Local (draft `Game`) + OM | `Game.*` |
| | "14-player cap · Waitlist ON" | Local | `Game.playerLimit`, `.waitlistEnabled` |
| | Publish game | Input → FS new `games/{id}` + `rsvps/{me}` (`isHost`, approved) + new `conversations/{id}` (`type: game`) | `Game`, `RSVP`, `Conversation` |
| H45 Game Created | "Pickup Soccer · Today · 7:00–8:30 PM · CMU Soccer Field · 0 / 14 joined · Approval ON" | FS `games/{id}` | `Game.*` |
| H20 Host Dashboard | Title, time, venue, "12 / 14 joined" | FS `games/{id}` | `Game.*` |
| | "2 requests / 2 waiting" | FS | `Game.pendingCount` |
| | "4 new messages" | FS `conversations/{conversationId}` | `Conversation.unreadCounts[me]` |
| | Edit game / Transfer host / Cancel game | Opens H46 / H22 / H38 | — |
| H46 Edit Game | Date, start/end, location, player limit, join type, description | FS `games/{id}` (prefilled) → Input update, `updatedAt` | `Game.startTime`, `.endTime`, `.venueId`, `.playerLimit`, `.joinType`, `.description` |
| | "Notify joined players about these changes" | Input → FS `users/{playerId}/notifications` (type `gameUpdated`, with `change`) for each approved RSVP + FCM | `AppNotification.change` (`GameChange`) |

## E — Moderation & Host Settings

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H21 Join Requests | "2 waiting · 2 spots left" | FS `games/{id}` | `Game.pendingCount`, `.spotsLeft` |
| | Each request: initials, name, attendance %, level, note | FS `games/{id}/rsvps` where `status == pending` | `RSVP.displayName`, `.reliability`, `.skillLevel`, `.noteToHost` |
| | Approve / Decline | Input → FS `rsvps/{userId}.status`, `.respondedAt`, `.hostResponse`; update `joinedCount`/`pendingCount`; FS notification to player + FCM | `RSVP.status`, `AppNotification` (`approved`/`declined`) |
| H22 Transfer Host | Joined players with attendance % | FS `rsvps` where `status == approved` and `isHost == false` | `RSVP.displayName`, `.reliability` |
| | Transfer host | Input → FS `games/{id}.hostId`, `.hostName`; `rsvps` `isHost` swapped | `Game.hostId`, `RSVP.isHost` |

## F — Friends, Groups & Messaging

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H23 Friends Activity | "Mina is joining 7v7 at Schenley · Tonight 8:15 PM · 1.2 mi" | FS collection group `rsvps` where `userId in friendIds`, `status == approved`; then parent `games` | `RSVP.userId`, `Game.title`, `.startTime`, distance |
| | Join Mina | Opens H09 for that game | — |
| | "Chris joined CMU Tennis Club · 28 members · 4 mutuals" | FS collection group `members` where friend ID, recent `joinedAt`; `groups/{id}` | `GroupMember.joinedAt`, `PlayGroup.memberCount` |
| | People you may know "2 shared games · Soccer", "3 mutual friends" | Computed from past `rsvps` and friends-of-friends | `RSVP`, `Friendship.mutualCount` |
| | Add | as H10 Add friend | `Friendship` |
| H24 Direct Messages | Each row: name, last message, time, unread badge | FS `conversations` where `participantIds` array-contains me, ordered by `lastMessageAt` | `Conversation.title`, `.lastMessageText`, `.lastMessageAt`, `.unreadCounts[me]` |
| | Search friends or groups | Computed filter on loaded friends + conversations | `Friendship.displayName`, `Conversation.title` |
| H39 Message Thread | Header "Mina Kim · Friend · Soccer + Tennis" | FS `users/{otherId}` + Friends | `AppUser.displayName`, `.sportLevels`, `Friendship.status` |
| | Messages, input | as H16 (`type: direct`) | `Message` |
| H25 Groups Discover | Each group: name, description, mutual friends, member count | FS `groups` where `visibility == public`, `sports` array-contains-any user sports | `PlayGroup.name`, `.description`, `.memberCount` |
| | "4 mutual friends" | Computed: `groups/{id}/members` ∩ Friends | `GroupMember.id` |
| | "3 games this week" | FS `games` where `groupId == id`, `startTime` in this week (count query) | `Game.groupId` |
| | ＋ create group | Opens H47 | — |
| H26 Group Detail | Name, member count, mutuals, about | FS `groups/{id}` + Computed | `PlayGroup.*` |
| | Join group | Input → FS `groups/{id}/members/{me}` (`member`, or `pending` if `membershipType == requestToJoin`), `memberCount += 1` | `GroupMember.role` |
| | Pin to Home | Input → FS `private/settings` | `UserSettings.pinnedGroupIds` |
| | Upcoming games | FS `games` where `groupId == id`, `startTime >= now` | `Game.title`, `.startTime`, `.venueName` |
| | Open group chat | FS `conversations/{conversationId}` | `PlayGroup.conversationId` |
| H47 Create Group | Group photo | Input → Storage `groups/{id}/photo.jpg` | `PlayGroup.photoURL` |
| | Name, sports, local area, description, privacy, membership | Input → FS new `groups/{id}` + `members/{me}` (`owner`) + `conversations` (`type: group`) | `PlayGroup.name`, `.sports`, `.localArea`, `.description`, `.visibility`, `.membershipType` |

## G — My Games, History & Reputation

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H27 My Games | Upcoming tab: title, time, venue, status badge (APPROVED / PENDING / WAITLIST #2) | FS My RSVPs where game `startTime >= now` | `Game.*`, `RSVP.status`, `RSVP.waitlistPosition` |
| | Hosting tab | FS `games` where `hostId == me`, `status == scheduled` | `Game` |
| | Past tab | Opens H28 | — |
| H28 Past Games | Month header "6 games · 5 attended · 4 new friends · 3 reviews left" | Computed: My RSVPs with `endTime < now`, `RSVP.attended`, `Friendship.since` in month, `reviews` by me | `RSVP.attended`, `Friendship.since`, `Review.reviewerId` |
| | Each row: title, date, venue, REVIEW / SUMMARY badge | FS My RSVPs (past) + `reviews` where `reviewerId == me` and `gameId` | `Game.*`; badge = no `Review` yet |
| H29 Past Game Summary | Title, date, venue, ATTENDED, 14 players | FS `games/{id}` + `rsvps/{me}` | `Game.*`, `RSVP.attended`, `Game.joinedCount` |
| | "90 min played · Midfielder" | Computed + FS | `Game.endTime − startTime`, `AppUser.position` |
| | "You met 4 new players", Played-with avatars | Computed: `rsvps` (approved) minus existing Friends | `RSVP.displayName` |
| | Reconnect with players | as H10 Add friend | `Friendship` |
| | Your note | Input → FS `rsvps/{me}` | `RSVP.personalNote` |
| H30 Post-game Review | "How was playing with Jamie?", name, role | FS `rsvps` of game | `RSVP.displayName`, `.isHost` |
| | Feedback tags, comment | Input → FS new `reviews/{id}` | `Review.tags`, `Review.comment` |
| | Attendance reliability note | Computed from `PlayerStats` | `PlayerStats.reliability` |

## H — Settings, Safety & Guest Experience

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H31 Notifications | Latest items: type badge, title, body, age | FS `users/{me}/notifications` ordered by `createdAt`, limit 4 | `AppNotification.type`, `.title`, `.body`, `.createdAt` |
| | Unread state | FS | `AppNotification.isRead` |
| H32 Notification Settings | Six toggles | FS `private/settings` | `NotificationPrefs.*` |
| | "Soccer + Tennis · within 3.0 mi · Weekdays after 5 PM · Any skill" | FS `private/settings` | `NewGameAlertRule.sports`, `.radiusMiles`, `.weekdaysOnly`, `.earliestHour`, `.skillLevels` |
| H33 Safety & Reporting | "Report Jamie" | FS `users/{id}` | `AppUser.displayName` |
| | Reason radio, details | Input → FS new `reports/{id}` | `Report.reason`, `.details`, `.gameId` |
| | Block user instead | Input → FS `private/settings` | `UserSettings.blockedUserIds` |
| H34 Guest Join Gate | Game summary, "All Levels · Free · 2 spots" | FS `games/{id}` | `Game.skillLevel`, `.isFree`, `.spotsLeft` |
| | Shown when | Auth anonymous / FS | `AppUser.isGuest` |
| | Create account / Sign in | Auth (link anonymous account to email credential) | — |
| H35 Declined Request | DECLINED | FS `rsvps/{me}` | `RSVP.status` |
| | Host message "Keeping tonight's game to intermediate+…" | FS `rsvps/{me}` | `RSVP.hostResponse` |
| | Find similar All-Level games | FS nearby games, `skillLevel == allLevels` | `Game` |
| H36 Profile & Preferences | Initials, name, "Soccer · Tennis · Social / casual", level | FS `users/{me}` | `AppUser.initials`, `.displayName`, `.sportLevels`, `.playStyles` |
| | "94% · 17 / 18 RSVPs attended" | FS `users/{me}` | `PlayerStats.reliability`, `.gamesAttended`, `.gamesRSVPd` |
| | Favorite fields "CMU Soccer Field, Schenley Oval" | FS `private/settings` + `venues` | `UserSettings.favoriteVenueIds`, `Venue.name` |
| | Notifications "Important only" | Computed from FS | `NotificationPrefs` |
| | Privacy "Friends can see activity" | FS `private/settings` | `PrivacySettings.gameActivity` |
| | Account & security | Opens H59 | — |

## I — Confirmations & Conversation Threads

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H37 Leave Confirmation | "Pickup Soccer · APPROVED · Today 7:00 PM · CMU Soccer Field" | FS `games/{id}` + `rsvps/{me}` | `Game.*`, `RSVP.status` |
| | Leave game | Input → FS `rsvps/{me}.status = left`, `joinedCount -= 1`; first waitlisted RSVP gets `spotOfferExpiresAt` + `spotOpen` notification | `RSVP.status`, `RSVP.spotOfferExpiresAt` |
| H38 Cancel Game Confirmation | "12 joined players · 2 pending · Today 7:00 PM" | FS `games/{id}` | `Game.joinedCount`, `.pendingCount`, `.startTime` |
| | Cancel game | Input → FS `games/{id}.status = cancelled` + `gameCancelled` notification to every RSVP + FCM | `Game.status`, `AppNotification` |
| H39 Message Thread | (see section F) | | |

## J — Lo-fi Parity Screens

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H41 Sign In, H42 Skill Levels, H43 Notification Permission, H44 Onboarding Complete | (see section A) | | |
| H45 Game Created, H46 Edit Game | (see section D) | | |
| H47 Create Group | (see section F) | | |
| H48 Search | Search text, Games / Groups / People tabs | Local | — |
| | Game results with "2 spots", "$5" | FS `games` prefix query on `titleLowercase` + nearby filter — `titleLowercase` to `games` | `Game.title`, `.spotsLeft`, `.priceCents` |
| | Group matches "92 members · 5 games this week" | FS `groups` prefix query on `nameLowercase` (field) + count query | `PlayGroup.name`, `.memberCount` |
| | People | FS `users` prefix query on `displayNameLowercase` (field), respecting `PrivacySettings.profileVisibility` | `AppUser` |
| H49 Edit Profile | Photo, display name, home area, bio | FS `users/{me}` → Input update; photo → Storage | `AppUser.photoURL`, `.displayName`, `.homeArea`, `.bio` |
| | Sports & levels "Soccer · All Levels / Tennis · Casual" | FS `users/{me}` (edit opens H42) | `AppUser.sportLevels` |
| | Privacy | Opens H57 | `PrivacySettings.gameActivity` |

## K — Notification Pipelines & Profile Settings

All notification screens read one document from `users/{me}/notifications/{id}` (written by the action that caused it, and pushed with FCM). Opening one sets `isRead = true`.

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H50 All Notifications | Full list: type badge (APPROVED, UPDATE, CANCELLED, SPOT OPEN, MESSAGE, GROUP, RATE), title, body, age | FS `users/{me}/notifications` ordered by `createdAt` | `AppNotification.type`, `.title`, `.body`, `.createdAt` |
| H51 Game Update | "Pickup Soccer changed location · 12 minutes ago" | FS notification | `AppNotification.title`, `.createdAt` |
| | Old "CMU Upper Turf" / New "CMU Lower Turf" | FS notification | `GameChange.oldValue`, `.newValue`, `.field` |
| | Host quote "Lights are better on the lower turf" | FS notification | `GameChange.hostNote` |
| | View updated game / Open game chat | FS | `AppNotification.gameId`, `Game.conversationId` |
| H52 Game Cancelled | "Sunday Tennis" | FS notification + `games/{id}` | `Game.title`, `Game.status` |
| | "Organizer cancelled because courts are closed after rain" | FS `games/{id}.cancelReason` (entered on H38) | `Game.cancelReason`  |
| | "Your spot was released automatically. No payment was charged." | FS | `RSVP.status`, `Game.priceCents` |
| | Suggested "Indoor Tennis at CMU · Today · 8:30 PM · 2 spots" | FS nearby games, same `sport` | `Game.title`, `.startTime`, `.spotsLeft` |
| H53 Waitlist Spot Available | "You have 10 minutes to claim it" | FS `rsvps/{me}` / notification | `RSVP.spotOfferExpiresAt`, `AppNotification.expiresAt` |
| | Game "Tonight · 8:15–9:45 PM · Schenley Oval · 1.2 mi · 13 / 14 · Intermediate" | FS `games/{id}` + MK distance | `Game.*` |
| | Claim spot | Input → FS `rsvps/{me}.status = approved`, `joinedCount += 1`, `waitlistCount -= 1` | `RSVP.status` |
| H54 Message | Sender, "Pickup Soccer · Game chat", text, time | FS notification + `conversations/{id}/messages` | `Message.senderName`, `.text`, `.sentAt`, `Conversation.type` |
| H55 Group Activity | Group name, "Posted a new Tuesday pickup game" | FS notification + `groups/{id}` | `AppNotification.groupId`, `PlayGroup.name` |
| | "Tue · 8:00 PM · CMU Soccer Field · 5 spots" | FS `games/{id}` | `Game.startTime`, `.venueName`, `.spotsLeft` |
| H56 Favorite Fields | Each venue: name, distance, surface, lights, star | FS `venues` + `private/settings` + MK distance | `Venue.name`, `.surface`, `.hasLights`, `UserSettings.favoriteVenueIds` |
| | Add another field | Opens H40 | — |
| H57 Privacy Settings | Game activity, Profile visibility, Direct messages, Friend requests | FS `private/settings` | `PrivacySettings.*` (`AudienceSetting`) |
| | "2 blocked · manage list" | FS `private/settings` | `UserSettings.blockedUserIds.count` |
| H58 Reliability & Reviews | "94% · 17 / 18 games attended" | FS `users/{me}` | `PlayerStats.reliability`, `.gamesAttended`, `.gamesRSVPd` |
| | Feedback tags and quote | FS `users/{me}` | `PlayerStats.feedbackTagCounts`, `.recentFeedback` |
| | "16 of 18 teammates said Yes" | FS `users/{me}` | `PlayerStats.playAgainYes`, `.playAgainTotal` |
| | "2 MVP picks" | FS `users/{me}` | `PlayerStats.mvpCount` |
| H59 Account & Security | Email | Auth / FS `private/settings` | `UserSettings.email` |
| | Change password | Auth (`updatePassword`) | — |
| | Connected sign-in "Apple · Google" | Auth (`currentUser.providerData`) | — |
| | Download my data | FS export of all of the user's documents (V2) | — |
| | Delete account | Auth `delete()` + FS user documents removed | — |

## L — Post-game Player Review Flow

| Screen | Field on screen | Source | Struct.property |
|---|---|---|---|
| H60 Review Players | Each teammate: initials, name, role / position | FS `games/{id}/rsvps` (attended) + `users/{id}` | `RSVP.displayName`, `.isHost`, `AppUser.position` |
| | MVP choice (one per game) | Input (draft) | `Review.isMVP` |
| | Play again? Yes / No | Input (draft) | `Review.playAgain` |
| H63 Review Players Changed | Same as H60 with updated selection | Local draft | `Review.isMVP`, `Review.playAgain` |
| H61 Player Review Detail | Name, "Organizer · Midfielder", "★ Your MVP" | FS + Local draft | `RSVP.isHost`, `AppUser.position`, `Review.isMVP` |
| | What applied tags, comment | Input (draft) | `Review.tags`, `Review.comment` |
| H62 Review Summary | MVP name, "Play again: 4 Yes · 1 No" | Computed from drafts | `Review.isMVP`, `Review.playAgain` |
| | Submit all reviews | Input → FS one `reviews/{id}` per teammate; reviewee `stats` (`mvpCount`, `playAgainYes`, `playAgainTotal`, `feedbackTagCounts`) incremented | `Review`, `PlayerStats` |

---

## Schema changes found while mapping

These fields appeared on the wireframes but were missing from the first draft of the schema. All of them are now in Section 2, `Models.swift`, and the seed data.

| Field | Collection | Used on | Purpose |
|---|---|---|---|
| `stats.avgResponseMinutes: Int?` | `users` | H09, H12, H13 | "Host usually responds within 20 min" |
| `cancelReason: String?` | `games` | H38, H52 | Reason shown in the cancellation notice |
| `customSportName: String?` | `games` | H17 | Name for `sport == other` |
| `titleLowercase: String` | `games` | H48 | Prefix search (Firestore has no full-text search) |
| `nameLowercase: String` | `groups` | H48 | Prefix search |
| `displayNameLowercase: String` | `users` | H48, H24 | Prefix search |
| `mediaURL: String?` | `messages` | H16, H39 | Photo attachments in chat (V2) |
