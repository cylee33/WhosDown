# V1 feature briefs

**Version:** 0.4 · **Last updated:** 2026-11-06

One brief per V1 feature. Each brief is the single source for that feature: status, owner, hand-off note, screens, data, rules, acceptance checklist, and files to touch. How to claim and hand off: [CONTRIBUTING.md](../../CONTRIBUTING.md). New brief: copy [`_TEMPLATE.md`](_TEMPLATE.md).

**Where to look:**

| Question | Where |
|---|---|
| Which features are done? | This table, or the [project board](https://github.com/users/cylee33/projects/2) |
| Who is building or built a feature? | **Owner** here; the brief's status line; the GitHub issue's assignee |
| When was it finished, from which branch? | **Done on**, **Branch**, **PR** here; the PR page shows every commit |
| What exactly was done and what's left? | The brief's **Hand-off note** and acceptance checklist |
| Overall progress, with screenshots | [progress.md](../progress.md) |

**Dates are local (Pittsburgh) time.** GitHub shows merge times in UTC, which is 5 hours ahead, so an evening merge can look like the next day there.

**Keeping it current:** whoever claims a feature puts their name in **Owner** (and assigns the issue). The PR that finishes it fills in **Status**, **Done on**, **Branch**, and **PR**. The brief stays the source of truth if the two ever disagree.

| # | Feature | Lane | Phase | Status | Owner | Done on | Branch | PR |
|---|---|---|---|---|---|---|---|---|
| 1.1 | [Project setup](1.1-project-setup.md) | Core | 0 Foundation | Done | Chris Lee | 2026-11-02 | `feat/1.1-project-setup`, `feat/1.1-firebase-plist` | [#29](https://github.com/cylee33/WhosDown/pull/29), [#30](https://github.com/cylee33/WhosDown/pull/30) |
| 1.2 | [Account and sign-in](1.2-account-and-sign-in.md) | A Identity & Profile | 1 Identity | Done | Chris Lee | 2026-11-02 | `feat/1.2-account-and-sign-in` | [#31](https://github.com/cylee33/WhosDown/pull/31) |
| 1.3 | [Guest browsing](1.3-guest-browsing.md) | A Identity & Profile | 1 Identity | Done | Chris Lee | 2026-11-02 | `feat/1.3-guest-browsing`, `fix/1.3-signout-after-reinstall` | [#32](https://github.com/cylee33/WhosDown/pull/32), [#35](https://github.com/cylee33/WhosDown/pull/35) |
| 1.4 | [Onboarding](1.4-onboarding.md) | A Identity & Profile | 1 Identity | Done | Chris Lee | 2026-11-02 | `feat/1.4-onboarding` | [#33](https://github.com/cylee33/WhosDown/pull/33) |
| 1.5 | [Discover map](1.5-discover-map.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.6 | [Discover list](1.6-discover-list.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.7 | [Filters](1.7-filters.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.8 | [Match details](1.8-match-details.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.9 | [Weather](1.9-weather.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.10 | [Player roster](1.10-player-roster.md) | B Discover & Hosting | 3 Discover | Done | Chris Lee | 2026-11-02 | `feat/phase-3-discover` | [#39](https://github.com/cylee33/WhosDown/pull/39) |
| 1.11 | [Create Match](1.11-create-match.md) | B Discover & Hosting | 2 Hosting | Done | Chris Lee | 2026-11-02 | `feat/1.11-create-match` | [#38](https://github.com/cylee33/WhosDown/pull/38) |
| 1.12 | [Choose location](1.12-choose-location.md) | B Discover & Hosting | 2 Hosting | Done | Chris Lee | 2026-11-02 | `feat/1.12-choose-location` | [#37](https://github.com/cylee33/WhosDown/pull/37) |
| 1.13 | [Join an open Match](1.13-join-open-match.md) | C Joining & Lifecycle | 4 Joining | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.14 | [Request to join](1.14-request-to-join.md) | C Joining & Lifecycle | 4 Joining | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.15 | [Host: approve or decline](1.15-host-approve-decline.md) | C Joining & Lifecycle | 4 Joining | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.16 | [Leave Match or cancel request](1.16-leave-or-cancel-request.md) | C Joining & Lifecycle | 4 Joining | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.17 | [Waitlist](1.17-waitlist.md) | C Joining & Lifecycle | 6 Lifecycle | Not started | — | — | — | — |
| 1.18 | [Edit and cancel Match](1.18-edit-and-cancel-match.md) | B Discover & Hosting | 6 Lifecycle | Not started | — | — | — | — |
| 1.19 | [My Matches](1.19-my-matches.md) | C Joining & Lifecycle | 5 Follow-through | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.20 | [Match chat](1.20-match-chat.md) | C Joining & Lifecycle | 5 Follow-through | Done | Kurt Schimmel | 2026-11-06 | `main` | — |
| 1.21 | [In-app notifications](1.21-in-app-notifications.md) | C Joining & Lifecycle | 6 Lifecycle | Not started | — | — | — | — |
| 1.22 | [Profile](1.22-profile.md) | A Identity & Profile | 1 Identity | Done | Chris Lee | 2026-11-02 | `feat/1.22-profile` | [#34](https://github.com/cylee33/WhosDown/pull/34) |
| 1.23 | [Add to calendar](1.23-add-to-calendar.md) | C Joining & Lifecycle | 7 Device + safety | Not started | — | — | — | — |
| 1.24 | [Match reminders](1.24-match-reminders.md) | C Joining & Lifecycle | 7 Device + safety | Not started | — | — | — | — |
| 1.25 | [Report a Player or Match](1.25-report.md) | A Identity & Profile | 7 Device + safety | Not started | — | — | — | — |
| 1.26 | [Layout and interaction pass](1.26-layout-and-interaction-pass.md) | Core | 8 Finish | Not started | — | — | — | — |
| 1.27 | [Host check-in](1.27-host-check-in.md) | C Joining & Lifecycle | 6 Lifecycle | Not started | — | — | — | — |
| 1.28 | [Transfer host](1.28-transfer-host.md) | B Discover & Hosting | 6 Lifecycle | Not started | — | — | — | — |
## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-02 | Chris Lee (with Claude) | All 28 briefs written (D30) |
| 0.2 | 2026-11-02 | Chris Lee (with Claude) | Owner, Done on, Branch, PR columns; "where to look" guide |
| 0.3 | 2026-11-06 | Kurt Schimmel | Phase 4 features 1.13–1.16 marked done |
| 0.4 | 2026-11-06 | Kurt Schimmel | Phase 5 features 1.19 and 1.20 marked done |
