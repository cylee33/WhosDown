# WhosDown V1 Build Plan

**Version:** 0.26 · **Last updated:** 2026-11-08 · **Status:** All feature implementation complete; release sign-off and deployment pending

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
| A — Identity & Profile | `Onboarding/`, `Profile/` (in `Views/` and `ViewModels/`) | 1.2, 1.3, 1.4, 1.22, 1.25 |
| B — Discover & Hosting | `Discover/`, `Host/` (in `Views/` and `ViewModels/`) | 1.5–1.12, 1.18, 1.28 |
| C — Joining & Lifecycle | `Match/`, `Notifications/` (in `Views/` and `ViewModels/`) | 1.13–1.17, 1.19–1.21, 1.23, 1.24, 1.27 |
| Core (Chris reviews) | `Models/`, `Views/DesignSystem/`, `firebase/` | 1.1, 1.26 |

- Every feature has a brief in [`docs/features/`](features/) so whoever picks it up next knows exactly what to do (D29). How to claim work and hand it off: [CONTRIBUTING.md](../CONTRIBUTING.md).

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
| 1.17 | Waitlist | Full Matches say "Full · Join waitlist" with the count; join waitlist; on Open Matches the first in line gets a freed spot automatically; on Approval-required Matches the Host approves from the waitlist (ADR-0008; no spot offer, no H53) | H15, H21 |
| 1.18 | Edit and cancel game | Host edits time, location, limit, join type; cancels with a reason; joined players get an in-app notification | H46, H38, H51, H52 |
| 1.19 | My Games | Upcoming (color-coded status), Hosting, and Past lists; games move to Past after they end | H27, H28 |
| 1.20 | Game chat | One chat per game, created on publish; live messages for approved players | H16 |
| 1.21 | In-app notifications | List and detail screens for approved, declined, Match updated, Match cancelled, spot opened (Host), Host transferred | H50–H52 |
| 1.22 | Profile | Own profile organized by sport with a level per sport; edit profile (photo, name, bio, home area, sports and levels); organizer profile | H36, H49, H10 |
| 1.23 | Add to calendar | Calendar event from a joined game | H14 |
| 1.24 | Game reminders | Local notification before each approved game; removed if the player leaves or the game is cancelled | H14, H27 |
| 1.25 | Report a user or game | Safety & Reporting form writes a report | H33 |
| 1.26 | Layout and interaction pass | Small steps (join review, leave / cancel confirmations, approve / decline) open as bottom sheets; spacing on a shared 8-point grid | H09, H12, H21, H37, H38 |
| **1.27** | **Host check-in** *(approved extra, ADR-0007)* | Host records which Players attended; this is the data behind Reliability (rules: D31) | New screen built in the existing design style, no Figma frame (D32); opens from H20 and the Host's past Matches (H28) |
| **1.28** | **Transfer host** *(approved extra, was V2 2.14)* | Host passes the Match to a joined Player; the Host cannot simply leave (rules: D33) | H22, H38 |

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
| D15 | ~~App target with feature folders + local `WhosDownCore` package~~ replaced by D49 | [ADR-0005](adr/0005-app-target-plus-core-package.md) |
| D16 | Swift: Xcode 27's default settings for new app projects (checked at project creation). Minimum iOS 26 (current minus one) | [architecture §4](architecture.md) |
| D17 | V1 has no server code: transactions on the device + strict security rules; Cloud Functions in V2 | [ADR-0006](adr/0006-v1-has-no-server-code.md) |
| D18 | ~~Radius search with GeoFireUtils~~ replaced by D50 | [architecture §2](architecture.md) |
| D19 | GitHub issues, board, labels, and PR template are created when the owner says "start coding" | §8 |
| D20 | Build order: phases 0–8 (§7); core loop done at end of Phase 5 | §7 |
| D21 | Three lanes + Core; lanes are a guide, anyone can take any lane; strong hand-off documentation required | §2 |
| D22 | 1.27 Host check-in added to V1 | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D23 | Private Matches are V2 only; every V1 Match is public | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D24 | Full Match rules: Join → Join waitlist (or "Full" if no waitlist); pending Join requests stay pending and can't be approved while full; 10-minute Spot offer passes down the line in one transaction when it expires; Host can't set the limit below the joined count | [GLOSSARY](../GLOSSARY.md) |
| D25 | Host can't leave their Match: only cancel, or transfer (1.28) | [ADR-0007](adr/0007-v1-scope-changes-checkin-transfer-private.md) |
| D26 | Match reminder: local notification 1 hour before start, no setting in V1 | §4 (1.24) |
| D27 | Guests can browse everything public (map, list, details, roster, weather); any action opens the H34 sheet | §4 (1.3) |
| D28 | Testing: domain rules test-first in `WhosDownTests`; security rules tested on the Firebase emulator (moved up to Phase 0); seed script in `firebase/seed/` runs against the emulator only unless asked; screens checked by hand against the wireframes | §7 |
| D29 | One brief per feature in `docs/features/` (status and owner + hand-off note, goal, screens, data, rules and edge cases, acceptance checklist, files to touch, changelog); each GitHub issue links its brief; `CONTRIBUTING.md` covers setup, claiming, branches, PRs; every PR updates its brief's hand-off note | [features/](features/) |
| D30 | All 28 briefs are written before coding, as the last planning step | §7 |
| D31 | Check-in (1.27): open from the Match's start until 48 hours after it ends; every approved Player starts as attended and the Host switches off no-shows, then submits; the Host counts as attended automatically; only checked-in Matches count toward Reliability; the Host can redo it until the window closes | [GLOSSARY](../GLOSSARY.md) |
| D32 | Check-in screen has no Figma frame; it is built to match the existing design (roster style of H11, Attended switch per row, Submit button) | §4 (1.27) |
| D33 | Transfer host (1.28): only to an approved Player in the Match; takes effect at once, no accept step; the former Host stays as an approved Player and may then leave; the new Host gets an in-app notification; the Host label moves in Match chat | [GLOSSARY](../GLOSSARY.md) |
| D34 | Font: SF Pro (system font) with Dynamic Type; Figma's Inter is treated as equivalent | [architecture §5](architecture.md) |
| D35 | V1 is light mode only; **dark mode is a stated V2 objective** | §9 |
| D36 | V1 runs in the simulator and on teammates' phones via free Xcode installs (7-day expiry); no TestFlight. Paid Apple Developer Program decided before V2 push work starts (push needs it) | §9 |
| D37 | Reliability is counted when shown, not stored: each RSVP holds `checkedIn` and `attended`; Reliability = attended ÷ checked-in, counted across the Player's RSVPs. No running totals on profiles | [architecture §2](architecture.md) |
| D38 | Notifications: a Player may write into another Player's inbox only as themselves, and only if they are that Match's Host or hold an RSVP in it; the recipient can only read, mark read, or delete | [architecture §2](architecture.md) |
| D39 | Match chat lives at `conversations/{matchId}/messages`; only approved Players and the Host read and post; chat stays open after the Match ends | [architecture §2](architecture.md) |
| D40 | New Firebase iOS app, bundle ID `edu.cmu.whosdown`; its `GoogleService-Info.plist` is committed (not a secret; rules protect the data) | [CONTRIBUTING](../CONTRIBUTING.md) |
| D41 | Seed data: Node script in `firebase/seed/`, emulator only (Pittsburgh Venues, ~10 Matches, 5 test Players); real project only on request, key kept out of git; `firebase` CLI installed at "start coding" | [CONTRIBUTING](../CONTRIBUTING.md) |
| D42 | Match times stored as timestamps, shown in the phone's time zone; no Venue time-zone field in V1 | [architecture §2](architecture.md) |
| D43 | Briefs: `CONTRIBUTING.md`, template, and samples 1.14 and 1.27 first for owner review; the other 26 follow in the same format | [features/](features/) |
| D44 | Reports (1.25) are only written in V1; Chris reviews them in the Firebase console; no admin screen | §4 (1.25) |
| D45 | Brief format approved (template + samples 1.14, 1.27); each brief keeps its own "Open questions", brought to Chris in batches | [features/](features/) |
| D46 | Round 8 brief answers: four tabs (no Friends tab in V1); Sign out row on H36; no profile document for Guests, Guest Profile tab shows an empty "+" profile with sign-in buttons; no level block on H04; one custom sport; stale names on old copies accepted; Discover re-queries after every pan; time filter presets plus custom days and time of day; the Host counts toward the player limit; optional Match title; "Waitlist when full" switch; three-question new Venue sheet; pending requests stay pending on join type change; Note to Players on edits; chat row preview without unread count; one notifications list with a bell; calendar events not updated; basic accessibility check | [features/](features/) |
| D47 | **No 10-minute Spot offer** (replaces that part of D24). Open Match: first in line gets a freed spot automatically. Approval required: Join waitlist needs no approval; H21 shows Join requests and Waitlist; the Host approves anyone while a spot is free and gets a `spotOpened` notification when someone leaves while people wait. H53 and `spotOpen` dropped | [ADR-0008](adr/0008-waitlist-without-spot-offers.md) |
| D48 | Notification permission: one iOS prompt on H05 "Continue" during onboarding; reminders on by default after that | [1.4](features/1.4-onboarding.md), [1.24](features/1.24-match-reminders.md) |
| D49 | Strict MVVM: three top-level folders `Models/`, `Views/`, `ViewModels/` (ViewModels play MVC's Controller role); no separate Swift package; tests in `WhosDownTests` | [ADR-0009](adr/0009-mvvm-three-top-level-folders.md) |
| D50 | GeoFireUtils (D18) is not used: even its newest version only supports Firebase below 13. 1.5 adds a small `Geohash` helper in `Models/Rules/`, ported from Firebase's `geofire-common` and tested against its output | [architecture §3](architecture.md) |
| D51 | Firebase project `whosdown-57e99` stays under Chris's personal Google account (a CMU account is deleted after graduation; the Sprint 3 report points at this project). Chris's CMU account (`cylee@andrew.cmu.edu`) was added as a co-Owner on 2026-11-02; teammates are added as members when useful. Project board: https://github.com/users/cylee33/projects/2 | [ADR-0004](adr/0004-firebase-backend.md) |
| D52 | Repo moved from the iCloud-synced Desktop to `~/Developer/WhosDown` (iCloud made " 2" conflict copies that broke the build); CONTRIBUTING tells teammates to clone outside iCloud | [lessons-learned](lessons-learned.md) |

## 6. Open questions

- See the current grilling round; settled answers move to §5.
- Per-feature questions live in each brief's "Open questions" section.

## 7. Phases and tasks

### Phase 0 — Planning

- [x] Read the history: IdeaDocs, Sprint 3 folder, 63 wireframes
- [x] Set up documentation (`docs/`, ADRs, glossary, this plan)
- [ ] Settle the open questions in §6
- [ ] Write the architecture blueprint in `architecture.md`
- [x] Break V1 into build phases here (D20)
- [x] Write `CONTRIBUTING.md` and the brief template (D29)
- [x] Write all 28 feature briefs in `docs/features/` (D30); index: [features/README.md](features/README.md)
- [x] Settle the briefs' open questions (round 8)
- [x] Round 9: waitlist without spot offers (1.17, ADR-0008), reminder permission (1.24)
- [x] Owner approves the plan ("start coding", 2026-11-02: "do Phase 0")

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
| 0 Foundation ✅ | 1.1: Xcode project (MVVM folders), models, repositories, design system, tab bar, security rules v1 + emulator tests, seed data | App launches on the tab bar against the emulator; rules tests pass |
| 1 Identity ✅ | 1.2, 1.3, 1.4, 1.22 | A new Player signs up, finishes onboarding, edits their profile; a Guest browses. **Done 2026-11-02** (PRs #31–#34) |
| 2 Hosting ✅ | 1.12, 1.11 | A Host publishes a Match at a searched Venue. **Done 2026-11-02** (PRs #37–#38) |
| 3 Discover ✅ | 1.5, 1.6, 1.7, 1.8, 1.9, 1.10 | A Player finds that Match on the map and list and opens its details. **Done 2026-11-02**, approved by Chris in the simulator |
| 4 Joining ✅ | 1.13, 1.14, 1.15, 1.16 | Open join, Join request, approve/decline, leave. **Done 2026-11-06.** Two-device hand check still open |
| 5 Follow-through ✅ | 1.19, 1.20 | **Core loop screens done 2026-11-06.** Two-device hand check still open |
| 6 Lifecycle ✅ | 1.17, 1.18, 1.21, 1.27, 1.28 | Waitlist, edit/cancel, notifications, check-in, transfer. **Done 2026-11-06.** Two-device hand check still open |
| 7 Device + safety | 1.23, 1.24, 1.25 | Done 2026-11-08; feature implementation and automated Calendar/reminder/report acceptance pass |
| 8 Finish | 1.26, final security rules + tests | All code and source audit complete 2026-11-08; [interactive acceptance and deployment](phase-8-audit.md) pending |

### Later

- [x] 2026-11-13: branch protection on `main` (PR + 1 approval; not enforced for admins); Jaimin and Kurt are collaborators (D14)

## 9. V2 objectives already decided

Recorded here so they are not lost while V1 is built. The full V2 list is features 2.1–2.23 in the Sprint 3 document.

- **Dark mode** across every screen (D35). Needs dark versions of the design colors first.
- **Accessibility** beyond V1's basic check: full VoiceOver flow, contrast, Reduce Motion (D46).
- **Private Matches** with invites and share links (ADR-0007).
- **Push notifications** with Cloud Functions (ADR-0006); needs the paid Apple Developer Program, to be decided before this work starts (D36).


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
| 0.8 | 2026-11-02 | Chris Lee (with Claude) | Round 5: feature briefs + CONTRIBUTING (D29–D30), check-in rules and screen (D31–D32), transfer rules (D33), SF Pro (D34), light mode only with dark mode as V2 objective (D35), free device installs (D36); new §9 V2 objectives |
| 0.9 | 2026-11-02 | Chris Lee (with Claude) | Round 6: Reliability counted on read (D37), notification write rule (D38), Match chat (D39), bundle ID + plist (D40), seed data (D41), time zone (D42), brief rollout (D43) |
| 0.10 | 2026-11-02 | Chris Lee (with Claude) | Round 7: reports reviewed in console (D44), brief format approved (D45) |
| 0.11 | 2026-11-02 | Chris Lee (with Claude) | All 28 feature briefs written; feature index |
| 0.12 | 2026-11-02 | Chris Lee (with Claude) | Round 8 answers (D46), spot offers dropped (D47), accessibility added to V2 objectives |
| 0.13 | 2026-11-02 | Chris Lee (with Claude) | Round 9: waitlist without spot offers (D47, ADR-0008), permission prompt on H05 (D48) |
| 0.14 | 2026-11-02 | Chris Lee (with Claude) | MVVM folder layout (D49, ADR-0009) replaces D15 |
| 0.15 | 2026-11-02 | Chris Lee (with Claude) | D50: geohash helper instead of GeoFireUtils |
| 0.16 | 2026-11-02 | Chris Lee (with Claude) | Phase 0 built (1.1 in review: board and plist left) |
| 0.17 | 2026-11-02 | Chris Lee (with Claude) | D51: Firebase project stays on personal account; project board created |
| 0.18 | 2026-11-02 | Chris Lee (with Claude) | Phase 0 done (1.1); CMU account co-Owner |
| 0.19 | 2026-11-02 | Chris Lee (with Claude) | Phase 0 and Phase 1 done; D52 repo location |
| 0.20 | 2026-11-02 | Chris Lee (with Claude) | Phase 2 done |
| 0.21 | 2026-11-02 | Chris Lee (with Claude) | Phase 3 done |
| 0.22 | 2026-11-06 | Kurt Schimmel | Phase 4 done |
| 0.23 | 2026-11-06 | Kurt Schimmel | Phase 5 done |
| 0.24 | 2026-11-06 | Kurt Schimmel | Phase 6 done |

| 0.25 | 2026-11-08 | Codex | Phase 7/8 code implemented with tests; final device acceptance and deployment tracked separately |

| 0.26 | 2026-11-08 | Codex | Finished remaining implementation gaps with Swift/OS notification/simulator UI acceptance; release sign-off and Firebase deployment access tracked separately |
| 0.27 | 2026-11-13 | Chris Lee (with Claude) | Branch protection on; Storage deployed |
