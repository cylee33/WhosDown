# WhosDown V1 Build Plan

**Version:** 0.3 · **Last updated:** 2026-11-01 · **Status:** planning (no code until the owner says "start coding" or "do phase X")

## 1. Goal

Build **WhosDown V1**: the native iOS app that delivers all 26 Version 1 features approved in Sprint 3 (§9.2 of the final Sprint 3 document), each one complete. See [ADR-0003](adr/0003-v1-scope-is-the-approved-feature-list.md).

**V1 is done when** a host on one device creates an approval-required game, and a player on another device finds it on the map, requests to join, gets approved, sees it in My Games, and messages in its game chat, all with real backend data, and every other V1 feature below works end to end.

## 2. Who builds what

- **Chris Lee** builds the foundation and the first working prototype of V1 in this phase.
- **Jaimin Fee and Kurt Schimmel** then add and improve features in parallel.
- The repository and code structure must let several people work at once without blocking each other (see [architecture.md](architecture.md)).

## 3. Timeline

| Phase | When | What |
|---|---|---|
| V1 foundation + prototype | Within ~1 week of 2026-11-01 | Foundation and the 26 V1 features, core loop first |
| V1 polish + V2 | After that, ongoing | Teammates improve V1 features in parallel; V2 features (2.1–2.23) follow |

The Sprint 3 week-by-week dates (Oct 26 → Nov 16) are replaced by this timeline. Exact build order: _open, see §6_.

## 4. V1 features (from Sprint 3 §9.2)

| # | Feature | What works in V1 | Screens |
|---|---|---|---|
| 1.1 | Project setup | Xcode project, backend SDK, data models, sample data, security rules (owner-only private settings) | — |
| 1.2 | Account and sign-in | Email sign-up, sign-in, sign-out, password reset | H01, H02, H41 |
| 1.3 | Guest browsing | Anonymous sign-in; guest can browse; Join opens the guest gate, which upgrades the account | H01, H34 |
| 1.4 | Onboarding | All nine sports plus "Other" with a custom name, skill level per sport, basic profile (name, bio, home area, play style), location permission, notification preferences saved | H03, H42, H04, H05, H44 |
| 1.5 | Discover map | Map with user location, radius circle, sport pins from the nearby-games query, pin card, "Next up" card | H06 |
| 1.6 | Discover list | Nearby games with distance, level, count, price | H07 |
| 1.7 | Filters | Sport, time (Now / Tonight / Tomorrow / custom range), distance typed in miles, skill, join type; distance saved to settings | H08 |
| 1.8 | Game detail | All game facts, distance, venue facts, attendee preview; whole organizer row opens the organizer profile; note that the game moves to Past Games after it ends | H09 |
| 1.9 | Weather | Open-Meteo weather line for outdoor games | H09, H14, H18, H19 |
| 1.10 | Player roster | Approved players with level and reliability | H11 |
| 1.11 | Create game | Sport (including custom "Other"), date/time, skill, player limit, join type, visibility, price (display only), notes, facility details | H17, H18, H19, H45 |
| 1.12 | Choose location | Place search + saved venues; new place saved as a venue | H40 |
| 1.13 | Join an open game | One-tap join; counters update live | H09, H14 |
| 1.14 | Request to join | Join review explains the three approval steps; note to host; Pending; live change to Approved or Declined (with host message); one color per status | H12, H13, H14, H35 |
| 1.15 | Host: approve / decline | Host dashboard and join-request list | H20, H21 |
| 1.16 | Leave game / cancel request | "Leave game" or "Cancel request" on Game Detail whenever the player has an RSVP; confirmation sheet; counters update | H09, H13, H37 |
| 1.17 | Waitlist | Full games say "Full · Join waitlist" with the count; join waitlist; first in line gets a 10-minute spot offer when someone leaves; claim spot | H15, H53 |
| 1.18 | Edit and cancel game | Host edits time, location, limit, join type; cancels with a reason; joined players get an in-app notification | H46, H38, H51, H52 |
| 1.19 | My Games | Upcoming (color-coded status), Hosting, and Past lists; games move to Past after they end | H27, H28 |
| 1.20 | Game chat | One chat per game, created on publish; live messages for approved players | H16 |
| 1.21 | In-app notifications | List and detail screens for approved, declined, game updated, game cancelled, spot open | H31, H50–H53 |
| 1.22 | Profile | Own profile organized by sport with a level per sport; edit profile (photo, name, bio, home area, sports and levels); organizer profile | H36, H49, H10 |
| 1.23 | Add to calendar | Calendar event from a joined game | H14 |
| 1.24 | Game reminders | Local notification before each approved game; removed if the player leaves or the game is cancelled | H14, H27 |
| 1.25 | Report a user or game | Safety & Reporting form writes a report | H33 |
| 1.26 | Layout and interaction pass | Small steps (join review, leave / cancel confirmations, approve / decline) open as bottom sheets; spacing on a shared 8-point grid | H09, H12, H21, H37, H38 |

**Design guide:** the Figma hi-fi wireframes are the reference for every screen. Build with standard SwiftUI components made as close to the wireframes as possible (layout, wording, colors, status colors, spacing).

## 5. Settled decisions

| # | Decision | Record |
|---|---|---|
| D1 | All 26 V1 features are required and complete; extras only with Chris's approval; core loop first | [ADR-0003](adr/0003-v1-scope-is-the-approved-feature-list.md) |
| D2 | Chris builds the foundation and first prototype; teammates extend in parallel; repo structured for parallel work | §2 |
| D3 | One git repo at `WhosDown/`, private GitHub repo `cylee33/WhosDown`; history folders included; Jaimin and Kurt added later | [repo](https://github.com/cylee33/WhosDown) |
| D4 | Sprint 3 code is reference only | [ADR-0002](adr/0002-sprint3-code-is-reference-only.md) |
| D5 | SwiftUI + `@Observable` view models + repositories; no direct backend calls from views or view models without asking | [ADR-0001](adr/0001-swiftui-observable-view-models-with-repositories.md) |
| D6 | Figma wireframes are the design guide; standard SwiftUI parts as close as possible | §4 |
| D7 | Local emulator testing is wanted but low priority; move it up only if development needs it | §7 |
| D8 | Native Xcode SwiftUI app (not Expo / React Native) | [ADR-0001](adr/0001-swiftui-observable-view-models-with-repositories.md) |
| D9 | Firebase backend, existing project `whosdown-57e99` | [ADR-0004](adr/0004-firebase-backend.md) |

## 6. Open questions

- Branch, issue, and review workflow on GitHub.
- Xcode project structure, minimum iOS version, Swift language mode.
- Where server-side rules live in V1 (client transactions + security rules vs. Cloud Functions).
- Meaning of the timeline (V1 in ~1 week, then V1 polish and V2 together?).
- Build order of the 26 features, and how the work is split into parallel lanes.
- Domain words: Game vs Activity vs Event; Host vs Organizer; RSVP vs Join request.

## 7. Phases and tasks

### Phase 0 — Planning

- [x] Read the history: IdeaDocs, Sprint 3 folder, 63 wireframes
- [x] Set up documentation (`docs/`, ADRs, glossary, this plan)
- [ ] Settle the open questions in §6
- [ ] Write the architecture blueprint in `architecture.md`
- [ ] Break V1 into build phases here
- [ ] Owner approves the plan ("start coding")

### Later

- Local emulator setup (low priority, D7).

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-01 | Chris Lee (with Claude) | First draft: goal, sources, V1 feature list |
| 0.2 | 2026-11-01 | Chris Lee (with Claude) | Round 1 decisions D1–D7; new timeline (V1 within ~1 week, then V2); moved from `brain/` to `docs/` |
| 0.3 | 2026-11-01 | Chris Lee (with Claude) | Round 2: native SwiftUI confirmed (D8), Firebase kept (D9, ADR-0004), private GitHub repo created (D3) |
