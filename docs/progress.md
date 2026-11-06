# WhosDown V1 Progress

**Version:** 0.5 · **Last updated:** 2026-11-06 · **Status:** Phases 0–5 done; Phase 6 next

Where the V1 build stands, what you can see in the app today, and how to try it yourself. Update this page at the end of every phase. The [build plan](v1-build-plan.md) has the phases; each [feature brief](features/) has the details.

## 1. At a glance

| | |
|---|---|
| Features done | **19 of 28** (1.1–1.16, 1.19, 1.20, 1.22) |
| Phases done | **0–5** (of 0–8). The core loop's screens are in place. |
| Swift tests | **101 passing** (10 of them run the real Firebase code against the local emulator) |
| Security-rule tests | **60 passing** (Firestore and Storage) |
| Pull requests merged | #29–#39 |
| Core loop ("V1 is done when", plan §1) | Not yet; needs Phases 2–5 |

## 2. Phases

| Phase | Features | Status |
|---|---|---|
| 0 Foundation | 1.1 | ✅ Done (PRs #29, #30) |
| 1 Identity | 1.2, 1.3, 1.4, 1.22 | ✅ Done (PRs #31–#35) |
| 2 Hosting | 1.12, 1.11 | ✅ Done (PRs #37, #38) |
| 3 Discover | 1.5–1.10 | ✅ Done (PR #39), approved by Chris in the simulator |
| 4 Joining | 1.13–1.16 | ✅ Done (2026-11-06) |
| 5 Follow-through | 1.19, 1.20 | ✅ Done (2026-11-06) |
| 6 Lifecycle | 1.17, 1.18, 1.21, 1.27, 1.28 | Not started |
| 7 Device + safety | 1.23, 1.24, 1.25 | Not started |
| 8 Finish | 1.26, final rules | Not started |

## 3. What works now

**Foundation (1.1)**

- Xcode project in strict MVVM folders: `Models/`, `Views/`, `ViewModels/` (ADR-0009). Firebase 13.1.1, iOS 26, Xcode 27's default Swift settings.
- Debug builds run against the local Firebase emulator as `demo-whosdown`; Release builds use the real `whosdown-57e99`.
- Seed data: 6 test Players, 5 Pittsburgh Venues, 10 Matches covering every case ([firebase/seed/README.md](../firebase/seed/README.md)).
- GitHub: issues #1–#28, [project board](https://github.com/users/cylee33/projects/2), PR template.

**Account and sign-in (1.2):** create account, sign in, password reset, sign out. Errors are plain sentences, and the app stays signed in between launches.

**Guest browsing (1.3):** "Explore as guest" lets someone browse without an account. Anything that needs an account opens the sign-in sheet (H34). Creating an account from there keeps the same user, and the Guest stays on their screen. Matches, Create, and Profile show Guest versions.

**Onboarding (1.4):** H03 sports (plus a custom "Other") → H42 levels → H04 photo, play style, bio, home area → H05 location and notifications → H44. Each step saves as you go, and closing the app resumes where you stopped. Photos are cropped to 512 × 512 and stored in Firebase Storage.

**Profile (1.22):** your own profile (H36) with sports and levels, Reliability, and Sign out; editing (H49); other Players' profiles (H10). Reliability is counted from check-ins (R20) and is ready for 1.10 to reuse.

**Choose location (1.12):** H40 shows saved Venues within 5 miles, nearest first, and Apple Maps search. A new place is saved as a Venue after three quick questions (indoor/outdoor, surface, lights), and the same field is never saved twice. A Swift port of Firebase's geohash library powers the radius search (D50).

**Create Match (1.11):** H17 essentials → H18 Venue & details → H19 review → publish → H45. The Host counts as the first Player, the title defaults to "Pickup {Sport}", and the Match, the Host's RSVP, and the Match chat are written together, so new Matches show up in Discover right away.

**Discover (1.5–1.10):** a map of nearby Matches (sport pins per Venue, radius circle, "Next up"), a list sorted soonest first, filters (sport, time incl. custom days and hours, distance, skill, join type), live Match details with weather, Venue facts, players and the Host, and the roster with Reliability.

**Joining (1.13–1.16):** an Open Match joins in one tap and shows H14. An Approval-required Match opens the H12 sheet, writes a pending RSVP, and turns green or red when the Host approves or declines from H20/H21. Leave and cancel-request confirm with a bottom sheet. Guests still hit H34. The Host has Manage Match and no Leave button. "Full · Join waitlist" shows on a full Match; joining the line is Phase 6. Chat and calendar buttons on H14 wait for 1.20 and 1.23.

**My Matches (1.19):** Upcoming, Hosting, and Past. Hosting opens the dashboard. A Match moves to Past on the device once it ends.

**Match chat (1.20):** approved Players and the Host post in H16. The Host's messages are labeled. Entry points are H14 and H20.

**Placeholders until their feature is built:** Edit, transfer, check-in, and cancel on the Host dashboard wait for Phase 6. The calendar button on H14 waits for 1.23. The inbox bell waits for 1.21.

## 4. Screens in the simulator

Taken on 2026-11-02 from the Debug build against the seeded emulator.

| Welcome (H01) | Guest: Discover | Guest: Matches tab | Guest: Profile tab |
|---|---|---|---|
| ![Welcome](progress/01-welcome.jpg) | ![Guest Discover](progress/02-guest-discover.jpg) | ![Guest Matches](progress/03-guest-matches.jpg) | ![Guest Profile](progress/04-guest-profile.jpg) |

| Onboarding: sports (H03) | Discover map (H06) | Profile (H36) | Create Match (H17) |
|---|---|---|---|
| ![Onboarding sports](progress/05-onboarding-sports.jpg) | ![Discover map](progress/09-discover-map.jpg) | ![Profile](progress/07-profile.jpg) | ![Create Match](progress/08-create-match.jpg) |

**Not yet checked by hand:** H02, H41, H34, H42, H04, H05, H44, H49, H10, H40, H18, H19, H45. Scripts can't tap the simulator, so these are covered by tests and SwiftUI previews only. Check them against Figma in the 1.26 audit, or tap through them in Xcode.

## 5. Try it yourself

1. Follow [CONTRIBUTING §2](../CONTRIBUTING.md) once: clone outside iCloud, `npm install` in `firebase/`, Java 21.
2. Terminal 1: `cd firebase && npm run emulators`. Terminal 2: `cd firebase && npm run seed`.
3. Open `app/WhosDown.xcodeproj`, choose an iOS 26 simulator, and press Run.
4. To skip typing, set these in the scheme (Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables):

| Variable | Opens as |
|---|---|
| `WHOSDOWN_DEV_SIGNIN=1` | Alex, a seeded Player |
| `WHOSDOWN_DEV_SIGNIN=guest` | A Guest |
| `WHOSDOWN_DEV_SIGNIN=newbie@whosdown.test` | A Player who hasn't finished onboarding |
| `WHOSDOWN_DEV_TAB=profile` (or `matches`, `create`) | That tab |

All test passwords are `whosdown123`.

## 6. Changed or decided while building

| What | Why | Record |
|---|---|---|
| Strict MVVM folders replace feature folders + core package | Owner asked for Models / Views / ViewModels | ADR-0009, D49 |
| Waitlist without 10-minute spot offers | Owner's call: Open Matches move the line up automatically; the Host approves on Approval-required Matches | ADR-0008, D47 |
| Own geohash helper instead of GeoFireUtils | GeoFireUtils doesn't work with Firebase 13 | D50 |
| Data models without `@DocumentID` | Its wrapper conflicts with Xcode 27's concurrency defaults | lessons-learned |
| Repo moved to `~/Developer/WhosDown` | iCloud Desktop sync made " 2" copies that broke the build | D52 |
| First launch after install signs out | Firebase's sign-in survives uninstall (Keychain) | PR #35 |
| Reliability (R20) built in 1.22 | The profile shows it; 1.10 reuses it | 1.22 brief |

## 7. Next

- **Phase 6 Lifecycle:** 1.17 waitlist, 1.18 edit and cancel, 1.21 notifications, 1.27 check-in, 1.28 transfer host.
- **Still to tap through:** the core loop on two devices. Rules tests cover the writes.
- **Chris, around 2026-11-04:** once the Student Developer Pack is active, turn on branch protection for `main`, then add Jaimin and Kurt (D14).
- **Before 2026-11-24:** deploy real security rules to `whosdown-57e99` (test mode expires; 1.26).

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-02 | Chris Lee (with Claude) | First progress report: Phases 0 and 1, screenshots, how to run, decisions made while building |
| 0.2 | 2026-11-02 | Chris Lee (with Claude) | Phase 2 done: 1.12 and 1.11 |
| 0.3 | 2026-11-02 | Chris Lee (with Claude) | Phase 3 done |
| 0.4 | 2026-11-06 | Kurt Schimmel | Phase 4 done: join, request, approve/decline, leave |
| 0.5 | 2026-11-06 | Kurt Schimmel | Phase 5 done: My Matches and Match chat |
