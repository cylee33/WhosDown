# WhosDown Architecture

**Version:** 0.4 · **Last updated:** 2026-11-02 · **Status:** draft

Blueprint for building the app. Sections marked _open_ are still being decided in the [build plan](v1-build-plan.md).

## 1. Layers

```
SwiftUI views            (one feature folder per area: Onboarding, Discover, Match, Host, Profile, Notifications)
      │  read state, send user actions
      ▼
@Observable view models  (one per screen or flow)
      │  call
      ▼
Repositories             (one per domain: matches, RSVPs, users, venues, chat, notifications, reports)
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
| `conversations/{id}`, `messages/{id}` | Match chat (V1); direct and group chat (V2) |
| `reviews/{id}` | Post-game reviews (V2) |
| `reports/{id}` | Safety reports |

Known patterns from Sprint 3: RSVP document ID = user ID; counters change in the same transaction as the RSVP; geohash for radius search (computed with GeoFireUtils); lowercase name fields for prefix search.

V1 has no server code: shared writes happen in transactions on the device, and security rules decide who may write what ([ADR-0006](adr/0006-v1-has-no-server-code.md)).

Endpoints: reads R1–R19 and writes W1–W19, listed in Sprint 3 §8.2 and on the Figma data-mapping page.

## 3. External services

| Service | Use | Release |
|---|---|---|
| Apple MapKit + Core Location | Map, place search, user location, distance | V1 |
| GeoFireUtils (`geofire-objc`) | Geohash and radius query ranges | V1 |
| Open-Meteo | Weather line for outdoor games (free, no key) | V1 |
| EventKit | Add game to calendar | V1 |
| UserNotifications (local) | Game reminders | V1 |
| Push messaging | Push for approvals, changes, messages | V2 |

## 4. Repository layout

See [ADR-0005](adr/0005-app-target-plus-core-package.md).

```
WhosDown/                      ← git repo root
├── app/
│   ├── WhosDown.xcodeproj
│   ├── WhosDown/              ← app target, Xcode synchronized folders
│   │   ├── App/               ← app entry, tab bar, navigation, dependency setup
│   │   ├── DesignSystem/      ← colors, type, spacing (8-point grid), shared components
│   │   ├── Onboarding/
│   │   ├── Discover/
│   │   ├── Match/
│   │   ├── Host/
│   │   ├── Profile/
│   │   └── Notifications/
│   ├── WhosDownTests/
│   └── Packages/WhosDownCore/ ← models, repository protocols, Firebase repositories, domain rules + tests
├── firebase/                  ← firestore.rules, firestore.indexes.json, storage.rules, seed data
├── docs/                      ← plan, architecture, ADRs, lessons
├── GLOSSARY.md
├── IdeaDocs/                  ← history
└── WhosDown (Team 6) Sprint 3/ ← history (reference only, ADR-0002)
```

- **Minimum iOS:** 26. **Swift:** Xcode 27's defaults for new app projects (record the exact settings here when the project is created).

## 5. Design system

Lives in `app/WhosDown/DesignSystem/`. The Figma hi-fi page "03 — Hi-Fi Full Marks" is the source.

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
