# WhosDown V1 Build Plan

**Version:** 0.7 · **Last updated:** 2026-11-01 · **Status:** planning (no code until the owner says "start coding" or "do phase X")

## 1. Goal

Build **WhosDown V1**: the native iOS app that delivers all 26 Version 1 features approved in Sprint 3 (§9.2 of the final Sprint 3 document) plus the approved extras 1.27–1.28, each one complete. See [ADR-0003](adr/0003-v1-scope-is-the-approved-feature-list.md) and [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md).

**V1 is done when** a host on one device creates an approval-required game, and a player on another device finds it on the map, requests to join, gets approved, sees it in My Games, and messages in its game chat, all with real backend data, and every other V1 feature below works end to end.

## 2. Who builds what

- **Chris Lee** builds the foundation and the first working prototype of V1 in this phase.
- **Jaimin Fee and Kurt Schimmel** then add and improve features in parallel.
- The repository and code structure must let several people work at once without blocking each other (see [architecture.md](architecture.md)).
- **Lanes** (a planned split, not a lock — anyone, including one person doing all three, can pick up any lane):

| Lane | Folders | Features |
|---|---|---|
| A — Identity & Profile | `Onboarding/`, `Profile/` | 1.2, 1.3, 1.4, 1.22, 1.25 |
| B — Discover & Hosting | `Discover/`, `Host/` (create flow) | 1.5–1.12, 1.18, 1.28 |
| C — Joining & Lifecycle | `Match/`, `Notifications/` | 1.13–1.17, 1.19–1.21, 1.23, 1.24, 1.27 |
| Core (Chris reviews) | `Packages/WhosDownCore/`, `firebase/`, `DesignSystem/` | 1.1, 1.26 |

- Every feature must be documented well enough that whoever picks it up next knows exactly what to do (format: open question, round 5).

## 3. Timeline

| Phase | When | What |
|---|---|---|
| V1 foundation + prototype | Within ~1 week of 2026-11-01 | Foundation and the 26 V1 features, core loop first |
| V1 polish + V2 | After that, in parallel | Teammates improve V1 features and build V2 features (2.1–2.23) at the same time |

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
| 1.11 | Create Match | Sport (including custom "Other"), date/time, skill, player limit, join type, price (display only), notes, facility details. No Public/Private choice in V1 (ADR-0007) | H17, H18, H19, H45 |
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
| **1.27** | **Host check-in** *(approved extra, ADR-0007)* | Host records which Players attended; this is the data behind Reliability | _new screen, design open_ |
| **1.28** | **Transfer host** *(approved extra, was V2 2.14)* | Host passes the Match to a joined Player; the Host cannot simply leave | H22, H38 |

Feature names keep their Sprint 3 numbers; wording follows the glossary (Match, Host). V2 gains **Private Matches** (with invites and share links).

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
| D10 | GitHub workflow: one issue per V1 feature + project board; one branch per feature; PR template; `main` changed only by PR with one approval | §8 |
| D11 | Words: **Match** (not Game / activity / event), **Host** (not Organizer), **RSVP** = a Player's record for a Match in any status, **Join request** = a pending RSVP | [GLOSSARY](../GLOSSARY.md) |
| D12 | Timeline: V1 in about one week, then V1 polish and V2 developed together | §3 |
| D13 | **Match** and **Host** replace Game and Organizer everywhere: app text ("My Matches", "Match details", "Match chat"), code (`Match`, `MatchRepository`), and Firestore (`matches` collection) | [GLOSSARY](../GLOSSARY.md) |
| D14 | `main` protection: Student Developer Pack (free Pro) expected ~2026-11-04. Until then: feature branches + PRs from day one, Chris may self-merge while building alone. When Pro is active: turn on protection (PR-only, 1 approval) **before** adding Jaimin and Kurt | §8 |
| D15 | App target with feature folders + local `WhosDownCore` package + `firebase/` folder | [ADR-0005](adr/0005-app-target-plus-core-package.md) |
| D16 | Swift: Xcode 27's default settings for new app projects (checked at project creation). Minimum iOS 26 (current minus one) | [architecture §4](architecture.md) |
| D17 | V1 has no server code: transactions on the device + strict security rules; Cloud Functions in V2 | [ADR-0006](adr/0006-v1-has-no-server-code.md) |
| D18 | Radius search with GeoFireUtils (Firebase's geohash helper) | [architecture §2](architecture.md) |
| D19 | GitHub issues, board, labels, and PR template are created when the owner says "start coding" | §8 |
| D20 | Build order: phases 0–8 (§7); core loop done at end of Phase 5 | §7 |
| D21 | Three lanes + Core; lanes are a guide, anyone can take any lane; strong hand-off documentation required | §2 |
| D22 | 1.27 Host check-in added to V1 | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D23 | Private Matches are V2 only; every V1 Match is public | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D24 | Full Match rules: Join → Join waitlist (or "Full" if no waitlist); pending Join requests stay pending and can't be approved while full; 10-minute Spot offer passes down the line in one transaction when it expires; Host can't set the limit below the joined count | [GLOSSARY](../GLOSSARY.md) |
| D25 | Host can't leave their Match: only cancel, or transfer (1.28) | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D26 | Match reminder: local notification 1 hour before start, no setting in V1 | §4 (1.24) |
| D27 | Guests can browse everything public (map, list, details, roster, weather); any action opens the H34 sheet | §4 (1.3) |
| D28 | Testing: domain rules test-first in `WhosDownCore`; security rules tested on the Firebase emulator (moved up to Phase 0); seed script in `firebase/seed/` runs against the emulator only unless asked; screens checked by hand against the wireframes | §7 |

## 6. Open questions

- Build order of the 26 features, and how the work is split into parallel lanes.

## 7. Phases and tasks

### Phase 0 — Planning

- [x] Read the history: IdeaDocs, Sprint 3 folder, 63 wireframes
- [x] Set up documentation (`docs/`, ADRs, glossary, this plan)
- [ ] Settle the open questions in §6
- [ ] Write the architecture blueprint in `architecture.md`
- [ ] Break V1 into build phases here
- [ ] Owner approves the plan ("start coding")

## 8. Team workflow on GitHub

- **Issues:** one issue per V1 feature (1.1–1.26), tracked on a GitHub project board; people assign themselves to claim work.
- **Branches:** one per feature, for example `feat/1.13-join-open-match`.
- **Pull requests:** template asks which feature, which screens (H-numbers), and whether docs changed. One teammate approves; squash merge.
- **`main`:** changed only through pull requests. Enforced by GitHub once the Student Developer Pack is active; until then, a team rule.
- **Labels:** `V1`, `V2`, `core`, and one per feature area.
- **Created when:** the owner says "start coding" (D19).

### Build phases (D20)

| Phase | Features | Done when |
|---|---|---|
| 0 Foundation | 1.1: Xcode project, `WhosDownCore`, models, repositories, design system, tab bar, security rules v1 + emulator tests, seed data | App launches on the tab bar against the emulator; rules tests pass |
| 1 Identity | 1.2, 1.3, 1.4, 1.22 | A new Player signs up, finishes onboarding, edits their profile; a Guest browses |
| 2 Hosting | 1.12, 1.11 | A Host publishes a Match at a searched Venue |
| 3 Discover | 1.5, 1.6, 1.7, 1.8, 1.9, 1.10 | A Player finds that Match on the map and list and opens its details |
| 4 Joining | 1.13, 1.14, 1.15, 1.16 | Open join, Join request, approve/decline, leave all work across two devices |
| 5 Follow-through | 1.19, 1.20 | **Core loop done** (the "V1 is done when" scenario in §1) |
| 6 Lifecycle | 1.17, 1.18, 1.21, 1.27, 1.28 | Waitlist, edit/cancel, notifications, check-in, transfer |
| 7 Device + safety | 1.23, 1.24, 1.25 | Calendar, reminders, reports |
| 8 Finish | 1.26, final security rules + tests | All 28 features pass their acceptance checks |

### Later

- [ ] ~2026-11-04: Student Pack active → enable branch protection on `main` → add Jaimin and Kurt as collaborators (D14)


## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-01 | Chris Lee (with Claude) | First draft: goal, sources, V1 feature list |
| 0.2 | 2026-11-01 | Chris Lee (with Claude) | Round 1 decisions D1–D7; new timeline (V1 within ~1 week, then V2); moved from `brain/` to `docs/` |
| 0.3 | 2026-11-01 | Chris Lee (with Claude) | Round 2: native SwiftUI confirmed (D8), Firebase kept (D9, ADR-0004), private GitHub repo created (D3) |
| 0.4 | 2026-11-01 | Chris Lee (with Claude) | GitHub workflow (D10), Match / Host / RSVP / Join request words (D11), timeline clarified (D12) |
| 0.5 | 2026-11-01 | Chris Lee (with Claude) | Round 3: Match/Host everywhere (D13), branch protection (D14), repo layout (D15, ADR-0005), Swift/iOS (D16), no server code in V1 (D17, ADR-0006), GeoFireUtils (D18), issue timing (D19) |
| 0.6 | 2026-11-01 | Chris Lee (with Claude) | D14 updated: Student Pack in ~3 days; interim self-merge rule |
| 0.7 | 2026-11-01 | Chris Lee (with Claude) | Round 4: build order (D20), lanes (D21), extras 1.27 check-in and 1.28 transfer host, Private Matches to V2 (D22–D23, ADR-0007), full-Match rules (D24), Host can't leave (D25), reminder timing (D26), Guest scope (D27), testing and emulator moved to Phase 0 (D28) |
