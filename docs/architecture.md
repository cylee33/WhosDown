# WhosDown Architecture

**Version:** 0.11 · **Last updated:** 2026-11-08 · **Status:** draft

Blueprint for building the app. Sections marked _open_ are still being decided in the [build plan](v1-build-plan.md).

## 1. Layers

```
SwiftUI views            (Views/, one subfolder per area: Onboarding, Discover, Match, Host, Profile, Notifications)
      │  read state, send user actions
      ▼
@Observable view models  (ViewModels/, one per screen or flow)
      │  call
      ▼
Repositories             (Models/Repositories/, one per domain: matches, RSVPs, users, venues, chat, notifications, reports)
      │  the ONLY layer that talks to the backend
      ▼
Firebase SDK + device services (Firebase per ADR-0004; MapKit, Core Location, EventKit, UserNotifications, Open-Meteo)
```

Rule: views and view models never call the backend directly ([ADR-0001](adr/0001-swiftui-observable-view-models-with-repositories.md)).

## 2. Data model (starting point)

The Sprint 3 schema (§2 of the Sprint 3 document) is the starting point; the code is rewritten ([ADR-0002](adr/0002-sprint3-code-is-reference-only.md)).

| Collection | Holds |
|---|---|
| `users/{userId}` | Public profile and stats |
| `users/{userId}/private/settings` | Owner-only settings: email, notification prefs, privacy, blocked users, favorites, search radius |
| `users/{userId}/friends/{friendId}` | Friends (V2) |
| `users/{userId}/notifications/{id}` | In-app notification inbox |
| `venues/{venueId}` | Fields, courts, gyms |
| `matches/{matchId}` | Matches, with denormalized Host/Venue names and counters (was `games` in Sprint 3) |
| `matches/{matchId}/rsvps/{userId}` | One RSVP per Player per Match |
| `groups/…`, `members/…` | Groups (V2) |
| `conversations/{matchId}/messages/{id}` | Match chat (V1, document ID = Match ID); direct and group chat reuse `conversations/` in V2 |
| `reviews/{id}` | Post-game reviews (V2) |
| `reports/{id}` | Safety reports |

Changes from the Sprint 3 schema:

- `games` → `matches`, `gameId` → `matchId`, `gameUpdated` → `matchUpdated`, and so on (D13).
- No `visibility` field in V1 (every Match is public, ADR-0007).
- RSVP gains `checkedIn` (Bool). `attended` (Bool?) is set by Check-in. The RSVP no longer stores a `reliability` copy, and the profile no longer stores `gamesAttended` / `gamesRSVPd`. Reliability = (RSVPs with `checkedIn` and `attended`) ÷ (RSVPs with `checkedIn`), counted with Firestore count queries over the `rsvps` collection group (D37).
- Match gains `checkedInAt` (Timestamp?), set by the Host's Check-in.
- RSVP `waitlistPosition` and `spotOfferExpiresAt` are removed. The waiting order is `matches/{id}.waitlistIds` (array of user IDs, max 50), so rules can check "first in line"; position = index + 1 (ADR-0008, 1.17).
- User gains `onboardedAt` (Timestamp?) and `customSportName` (String?) (1.2, 1.4).
- Notification gains `fromUserId` (D38) and `changes: [{field, oldValue, newValue}]` plus `hostNote` in place of the single `change` (1.18). V1 types: `approved`, `declined`, `matchUpdated`, `matchCancelled`, `spotOpened` (to the Host), `hostTransferred` (1.21, ADR-0008).
- Conversation `type` is `"match"` for Match chat; `participantIds` and `unreadCounts` are not maintained in V1 (1.20).
- New endpoints: **R20** Reliability (count queries, 1.10) and **W20** Check-in (batch, 1.27).
- Times are Firestore Timestamps; the app shows them in the phone's time zone (D42).

Security-rule rules of thumb:

- A Player writes only their own RSVP, except the Host, who sets status on Join requests and Check-in fields.
- Notifications: create in another Player's inbox only as yourself (`fromUserId == auth.uid`), and only if you are the Match's Host or hold an RSVP in it; the recipient may only read, mark read, or delete (D38).
- Match chat: read and post only for approved Players and the Host (D39).

Known patterns from Sprint 3: RSVP document ID = user ID; counters change in the same transaction as the RSVP; geohash for radius search (computed with GeoFireUtils); lowercase name fields for prefix search.

V1 has no server code: shared writes happen in transactions on the device, and security rules decide who may write what ([ADR-0006](adr/0006-v1-has-no-server-code.md)).

Endpoints: reads R1–R19 and writes W1–W19, listed in Sprint 3 §8.2 and on the Figma data-mapping page.

## 3. External services

| Service | Use | Release |
|---|---|---|
| Apple MapKit + Core Location | Map, place search, user location, distance | V1 |
| `Geohash` helper in `Models/Rules/` (ported from Firebase's `geofire-common`) | Geohash and radius query ranges (D50; GeoFireUtils doesn't support Firebase 13) | V1 |
| Open-Meteo | Weather line for outdoor games (free, no key) | V1 |
| EventKit | Add game to calendar | V1 |
| UserNotifications (local) | Game reminders | V1 |
| Push messaging | Push for approvals, changes, messages | V2 |

Calendar export uses `CalendarEventBuilder` and the system event editor, without requesting full Calendar access. `ReminderSyncModel` runs above the tabs, listens to the signed-in Player's RSVPs/hosted Matches and individual Match updates, and passes a complete plan to `ReminderScheduler`. It restarts on foreground/account changes; the notification delegate routes a tapped reminder to Match details. Onboarding owns the single permission prompt. Reminder triggers use UTC/Gregorian components to preserve their absolute time through time-zone/calendar changes. The notification service boundary permits denial/retry/replacement tests plus an actual OS pending-request test. Reports use a create-only `ReportRepository`; review remains in the Firebase console.

## 4. Repository layout

Strict MVVM in three top-level folders; see [ADR-0009](adr/0009-mvvm-three-top-level-folders.md) (replaces ADR-0005).

```
WhosDown/                      ← git repo root
├── app/
│   ├── WhosDown.xcodeproj
│   ├── WhosDown/              ← app target (Xcode synchronized folders)
│   │   ├── App/               ← app entry, tab bar, dependency setup, emulator switch
│   │   ├── Models/
│   │   │   ├── Data/          ← structs and enums (Match, RSVP, UserProfile…)
│   │   │   ├── Repositories/  ← protocols + Firebase implementations; the ONLY Firebase access
│   │   │   ├── Services/      ← weather, location, calendar, reminders
│   │   │   ├── Rules/         ← domain rules (JoinRules, WaitlistRules…), formatting
│   │   │   └── Fakes/         ← in-memory repositories for previews and tests
│   │   ├── Views/
│   │   │   ├── DesignSystem/  ← colors, type, spacing (8-point grid), shared components
│   │   │   └── Onboarding/ Discover/ Match/ Host/ Profile/ Notifications/
│   │   └── ViewModels/
│   │       └── Onboarding/ Discover/ Match/ Host/ Profile/ Notifications/
│   └── WhosDownTests/         ← domain-rule and view-model tests
├── firebase/                  ← firestore.rules, firestore.indexes.json, storage.rules, tests/, seed/
├── docs/                      ← plan, architecture, ADRs, feature briefs, lessons
├── GLOSSARY.md, CONTRIBUTING.md
├── IdeaDocs/                  ← history
└── WhosDown (Team 6) Sprint 3/ ← history (reference only, ADR-0002)
```

- **Minimum iOS:** 26.0. iPhone only, portrait, light mode (`UIUserInterfaceStyle = Light`, D35).
- **Swift settings** = Xcode 27.2's defaults for a new SwiftUI app, read from Xcode's own project templates on 2026-11-02 (D16):
  - `SWIFT_VERSION = 5.0` (Swift 5 language mode on the Swift 6 compiler)
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target: code is main-actor by default)
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  - `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` (import every module you use, e.g. `import FirebaseCore`)
  - `STRING_CATALOG_GENERATE_SYMBOLS = YES`, `SWIFT_EMIT_LOC_STRINGS = YES` (app target)
  - `ENABLE_USER_SCRIPT_SANDBOXING = YES`, `GENERATE_INFOPLIST_FILE = YES`
- **Packages:** `firebase-ios-sdk` 13.1.1 (up to next major): FirebaseAuth, FirebaseFirestore, FirebaseStorage. Versions are pinned in `Package.resolved`.
- **Tests:** Swift Testing (`import Testing`) in `WhosDownTests`, hosted in the app.
- **Firebase switch:** Debug builds talk to the local emulator as demo project `demo-whosdown` (no plist needed); Release builds read `GoogleService-Info.plist` for `whosdown-57e99` (`App/FirebaseSetup.swift`).

## 5. Design system

Lives in `app/WhosDown/Views/DesignSystem/`. The Figma hi-fi page "03 — Hi-Fi Full Marks" is the source.

- **Font:** SF Pro (the system font) with Dynamic Type text styles. Figma uses Inter; treat it as equivalent (D34).
- **Color mode:** light only in V1; dark mode is a V2 objective (D35). Define colors as named tokens anyway, so V2 can add dark values without touching screens.
- **Spacing:** shared 8-point grid (1.26).
- **Screens without a Figma frame** (for example 1.27 Check-in): reuse existing components and the closest wireframe's layout (D32).

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-01 | Chris Lee (with Claude) | Draft: layers, data model starting point, external services; moved from `brain/` |
| 0.2 | 2026-11-01 | Chris Lee (with Claude) | Backend set to Firebase (ADR-0004) |
| 0.3 | 2026-11-01 | Chris Lee (with Claude) | Match naming, repository layout (ADR-0005), no server code in V1 (ADR-0006), GeoFireUtils, iOS 26 |
| 0.4 | 2026-11-02 | Chris Lee (with Claude) | §5 design system: SF Pro, light only in V1, color tokens, screens without frames |
| 0.5 | 2026-11-02 | Chris Lee (with Claude) | Schema changes from Sprint 3 (Reliability counted on read, Check-in fields, chat path), security-rule rules of thumb |
| 0.6 | 2026-11-02 | Chris Lee (with Claude) | Schema changes found while writing the feature briefs (waitlistedAt, onboardedAt, notification fields, R20, W20) |
| 0.7 | 2026-11-02 | Chris Lee (with Claude) | Waitlist without spot offers (ADR-0008): `waitlistIds`, `spotOpened` |
| 0.8 | 2026-11-02 | Chris Lee (with Claude) | Layout changed to strict MVVM folders (ADR-0009) |
| 0.9 | 2026-11-02 | Chris Lee (with Claude) | Swift settings recorded; geohash helper replaces GeoFireUtils (D50); Firebase switch |

| 0.10 | 2026-11-08 | Codex | Calendar editor, live local reminder reconciliation/routing and report repository implemented |

| 0.11 | 2026-11-08 | Codex | Notification service boundary, UTC triggers, and simulator UI acceptance target |
