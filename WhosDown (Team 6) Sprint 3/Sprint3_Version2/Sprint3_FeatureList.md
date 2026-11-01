# Feature List

**WhosDown** — feature list for TA approval
Chris Lee, Jaimin Fee, Kurt Schimmel (Team 6)

---

## Feature List and Delivery Schedule (V1 / V2)

This is the list of features we will deliver in Version 1 (end of Sprint 4) and Version 2 (final release). It is taken from Section 9 of our Sprint 3 deliverable and reflects our prototype user testing (Sprint 3, Section 7). Screen IDs (H01–H63) refer to our high-fidelity wireframes.


### 1. Scope rules

- **Version 1** is the end of Sprint 4. It delivers the core loop from Sprint 1: *find a nearby game → join it → show up*, and *post a game → manage who comes*. A Version 1 feature must work end to end with real Firestore data.
- **Version 2** is the final release. It adds the social, reputation, and push features that make users come back.
- Firestore counters and in-app notifications are written by the client in transactions in Version 1. Push notifications need a server to send them, so FCM sending (through Cloud Functions) is in Version 2.
- Dates are the start of each work week. Sprint end dates follow Canvas.
- User testing (Section 7) changed the plan: V1 gained game reminders (1.24), reporting (1.25), and a layout pass (1.26); V1 1.4, 1.7, 1.8, 1.11, 1.14, 1.16, 1.17, 1.19, and 1.22 gained clarity fixes testers asked for; and V2 gained 2.18–2.23.

### 2. Version 1 (end of Sprint 4)

| # | Feature | What works in V1 | Screens | Week of |
|---|---|---|---|---|
| 1.1 | Project setup | Xcode project, Firebase SDK, `Models.swift`, sample data in Firestore, Firestore security rules (owner-only `private/settings`) | — | Oct 26 |
| 1.2 | Account and sign-in | Email sign-up, sign-in, sign-out, password reset | H01, H02, H41 | Oct 26 |
| 1.3 | Guest browsing | Anonymous sign-in; guest can browse; Join opens the guest gate, which upgrades the account | H01, H34 | Oct 26 |
| 1.4 | Onboarding | Select from all nine sports plus "Other" with a custom name, skill level per sport, basic profile (name, bio, home area, play style), location permission, notification preferences saved | H03, H42, H04, H05, H44 | Oct 26 |
| 1.5 | Discover map | MapKit map with user location, radius circle, sport pins from the nearby-games query, pin card, "Next up" card | H06 | Nov 2 |
| 1.6 | Discover list | List of nearby games with distance, level, count, price | H07 | Nov 2 |
| 1.7 | Filters | Sport, time (Now / Tonight / Tomorrow / custom range), distance typed in miles, skill, join type; distance saved to settings | H08 | Nov 2 |
| 1.8 | Game detail | All game facts, distance, venue facts, attendee preview; whole organizer row opens the organizer profile; note that the game moves to Past Games after it ends | H09 | Nov 2 |
| 1.9 | Weather | Open-Meteo weather line for outdoor games | H09, H14, H18, H19 | Nov 2 |
| 1.10 | Player roster | Approved players with level and reliability | H11 | Nov 2 |
| 1.11 | Create game | Sport (including a custom "Other" sport), date/time, skill, player limit, join type, visibility, price (display only), notes, facility details | H17, H18, H19, H45 | Nov 9 |
| 1.12 | Choose location | MapKit place search + saved venues; new place saved as a venue | H40 | Nov 9 |
| 1.13 | Join an open game | One-tap join; counters update live | H09, H14 | Nov 9 |
| 1.14 | Request to join | Join review explains the three approval steps; note to host; Pending; live change to Approved or Declined (with host message); one color per status | H12, H13, H14, H35 | Nov 9 |
| 1.15 | Host: approve / decline | Host dashboard and join-request list | H20, H21 | Nov 9 |
| 1.16 | Leave game / cancel request | "Leave game" or "Cancel request" button on Game Detail whenever the player has an RSVP; confirmation sheet; counters update | H09, H13, H37 | Nov 9 |
| 1.17 | Waitlist | Full games say "Full · Join waitlist" with the waitlist count; join waitlist; first in line gets a 10-minute spot offer when someone leaves; claim spot | H15, H53 | Nov 16 |
| 1.18 | Edit and cancel game | Host edits time, location, limit, join type; cancels with a reason; joined players get an in-app notification | H46, H38, H51, H52 | Nov 16 |
| 1.19 | My Games | Upcoming (with color-coded status badge), Hosting, and Past lists; games move to Past automatically after they end | H27, H28 | Nov 16 |
| 1.20 | Game chat | One chat per game, created on publish; live messages for approved players | H16 | Nov 16 |
| 1.21 | In-app notifications | Notification list and detail screens for approved, declined, game updated, game cancelled, spot open | H31, H50–H53 | Nov 16 |
| 1.22 | Profile | View own profile organized by sport with a level per sport; edit profile (photo upload to Storage, name, bio, home area, sports and levels); view organizer profile | H36, H49, H10 | Nov 16 |
| 1.23 | Add to calendar | EventKit event from a joined game | H14 | Nov 16 |
| 1.24 | Game reminders *(from user testing)* | Local notification before each approved game, scheduled on the device when the RSVP is approved; removed if the player leaves or the game is cancelled | H14, H27 | Nov 16 |
| 1.25 | Report a user or game *(from user testing)* | Safety & Reporting form writes a `reports` document | H33 | Nov 16 |
| 1.26 | Layout and interaction pass *(from user testing)* | Small steps (join review, leave and cancel confirmations, approve or decline) open as bottom sheets instead of new screens; spacing and alignment on a shared 8-point grid | H09, H12, H21, H37, H38 | Nov 16 |

### 3. Version 2 (final release)

| # | Feature | What it adds | Screens | Week of |
|---|---|---|---|---|
| 2.1 | Friends | Send / accept friend requests; "friends attending" on game detail; friend tags on the roster | H10, H09, H11, H29 | Nov 23 |
| 2.2 | Direct messages | Conversation list, one-to-one threads, unread badges | H24, H39 | Nov 23 |
| 2.3 | Search | Prefix search for games, groups, and people | H48 | Nov 23 |
| 2.4 | Groups | Discover, detail, create (with photo), join (open or request), group chat, pin to home, group games | H25, H26, H47, H55 | Nov 30 |
| 2.5 | Friends activity feed | Games friends joined, groups friends joined, people you may know | H23 | Nov 30 |
| 2.6 | Post-game reviews | Review players (MVP, play again, tags, written comment), review summary, past game summary with "new players met" and personal note; review screens explain what each answer affects | H29, H30, H60–H63 | Nov 30 |
| 2.7 | Reliability and reputation | Attendance marking by host, reliability %, feedback tags, MVP count, host response time | H10, H36, H58 | Nov 30 |
| 2.8 | Safety | Block a user, manage blocked list (reporting is in V1, 1.25) | H33, H57 | Dec 7 |
| 2.9 | Privacy settings | Who can see activity, profile, message me, send friend requests | H57 | Dec 7 |
| 2.10 | Push notifications | FCM token on device; Cloud Functions send pushes for approvals, changes, cancellations, spot open, messages, group activity, review reminders | H43, H50–H55 | Dec 7 |
| 2.11 | Notification settings and new-game alerts | Notification toggles; "alert me when a matching game is posted" rule | H32, H08 | Dec 7 |
| 2.12 | Media | Game photos and clips on game detail; photo attachments in chat | H09, H18, H16 | Dec 7 |
| 2.13 | Favorite fields | Star venues; favorites shown first when choosing a location | H56, H40 | Dec 7 |
| 2.14 | Transfer host | Pass a game to another joined player | H22 | Dec 7 |
| 2.15 | Invite a friend to a game | In-app invite notification | H11, H14 | Dec 7 |
| 2.16 | Recommendations | "Why these?" ranking by sports, distance, and play style | H07 | Dec 7 |
| 2.17 | Account and security | Change password, Sign in with Apple, download my data, delete account | H59 | Dec 7 |
| 2.18 | Profile media *(from user testing)* | Photos and media on a player's profile; needs a new `mediaURLs` field on `users` | H36, H49 | Nov 30 |
| 2.19 | Group schedules *(from user testing)* | Recurring events on the group profile; filter groups by sport and skill level; add recurring events to the calendar | H25, H26 | Nov 30 |
| 2.20 | Labeled chats *(from user testing)* | Each chat in the list shows its type and its game or group name with the sport | H24 | Nov 23 |
| 2.21 | Hidden location until approved *(from user testing)* | For approval games, show only the area until the player is approved; the exact location moves to a subdocument only approved players can read | H09, H13, H14 | Dec 7 |
| 2.22 | Share a game or group *(from user testing)* | Share sheet with a link that opens the game or group in the app | H09, H26 | Nov 30 |
| 2.23 | Saved games *(from user testing)* | Save a game for later; needs a new `savedGameIds` field in `private/settings` | H09, H27 | Dec 7 |

### 4. Not planned

These were in our earlier ideas but are outside the semester scope:

- **In-app payments.** Games can show a price (`priceCents`), but payment is handled outside the app.
- **Field reservation with facilities.** Hosts enter reservation details by hand (`fieldReserved`, `reservationWindow`).
- **Coaching / tutoring marketplace.**
- **Non-sport hobbies.**

### 5. Risks to the V1 schedule

| Risk | Plan |
|---|---|
| Geohash radius query is new to the team | Build it in week 1 with the sample data; fall back to a bounding-box query on latitude if needed |
| Counter drift (`joinedCount` vs. real RSVPs) | All join, leave, approve, and waitlist writes use one Firestore transaction (W6–W9) |
| Waitlist spot offer timing without a server | V1 checks `spotOfferExpiresAt` on the device when the next user opens the game; V2 moves expiry to a Cloud Function |
