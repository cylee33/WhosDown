# WhosDown Architecture

**Version:** 0.1 · **Last updated:** 2026-11-01 · **Status:** draft

Blueprint for building the app. Sections marked _open_ are still being decided in the [build plan](v1-build-plan.md).

## 1. Layers

```
SwiftUI views            (one feature folder per area: Discover, Game, Host, Profile, ...)
      │  read state, send user actions
      ▼
@Observable view models  (one per screen or flow)
      │  call
      ▼
Repositories             (one per domain: games, RSVPs, users, venues, chat, notifications, reports)
      │  the ONLY layer that talks to the backend
      ▼
Backend SDK + device services (backend: open; MapKit, Core Location, EventKit, UserNotifications, Open-Meteo)
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
| `games/{gameId}` | Games, with denormalized host/venue names and counters |
| `games/{gameId}/rsvps/{userId}` | One RSVP per player per game |
| `groups/…`, `members/…` | Groups (V2) |
| `conversations/{id}`, `messages/{id}` | Game chat (V1); direct and group chat (V2) |
| `reviews/{id}` | Post-game reviews (V2) |
| `reports/{id}` | Safety reports |

Known patterns from Sprint 3: RSVP document ID = user ID; counters change in the same transaction as the RSVP; geohash for radius search; lowercase name fields for prefix search.

Endpoints: reads R1–R19 and writes W1–W19, listed in Sprint 3 §8.2 and on the Figma data-mapping page.

## 3. External services

| Service | Use | Release |
|---|---|---|
| Apple MapKit + Core Location | Map, place search, user location, distance | V1 |
| Open-Meteo | Weather line for outdoor games (free, no key) | V1 |
| EventKit | Add game to calendar | V1 |
| UserNotifications (local) | Game reminders | V1 |
| Push messaging | Push for approvals, changes, messages | V2 |

## 4. Repository layout

_Open — decided in plan §6._

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-01 | Chris Lee (with Claude) | Draft: layers, data model starting point, external services; moved from `brain/` |
