# Phase 8 acceptance and hand-off

**Version:** 0.4 · **Last updated:** 2026-11-09

All Phase 7 and Phase 8 feature implementation is complete on `feat/phases-7-8`. Release verification and production deployment are tracked separately below; an unchecked release check does not identify a missing feature implementation.

## Source audit

| Screens / area | Changes or review result |
|---|---|
| H01, H02, H41 account | Welcome scrolls at large text sizes; account forms already scroll and show network progress/errors. Copy uses Match. |
| H03, H42, H04, H05, H44 onboarding | Sports become a single column at accessibility sizes. Shared chips wrap within available width. Permissions and completion screens now scroll; location prompting prevents repeated taps. Notification permission remains exclusively in H05. |
| H06–H08 Discover and filters | Badge padding and colors use tokens; icon-only controls have labels. Filters remain a tall sheet because of their form length; drag handle and apply progress added. Segmented pickers become menus at accessibility sizes. Map pins are labelled buttons; recenter shows progress. |
| H09–H11 Match, Host profile, roster | Calendar and report actions added; direct navigation links work from every tab and notification entry. Player reports retain Match context. Text can wrap. Cancelled/ended Matches use the detail screen rather than the joined screen. |
| H12, H37, decline, H38, H22 | Join review, leave/cancel request, decline, cancel Match, and transfer use the shared scrollable sheet layout. Cancel and transfer now present as sheets. Errors stay visible in the sheet; network actions prevent repeat taps. |
| H13–H15 joining states | Existing status components retained. H14 calendar is active only before start; denied reminder permission has a once-per-account explanation. |
| H16 chat | Empty state, send/load progress, and duplicate-send protection added. Existing plain-language errors retained. |
| H17–H19, H40, H45 creation | Existing form/scroll layouts retained; Venue search now shows progress and an empty state, Venue-save errors stay inside the sheet, and join-type pickers adapt to accessibility sizes. Structural spacing and colors use tokens. |
| H20, H21, H46 management | Approve/decline/waitlist actions show progress and prevent duplicate taps. Check-in and edit show progress and loading errors; transfer removes management controls from the former Host. Edit/cancel/transfer are hidden once no longer available. |
| H27, H28 Matches | Existing empty states retained. Rows wrap and the segment picker becomes a menu at accessibility sizes. Roster/profile navigation now works from these Match details too. |
| H33 safety | Report reasons, optional details, destructive submit, private review explanation, emergency copy and success confirmation implemented. Blocking remains V2. Compared to the checked-in mapped H33 wireframe; reasons use cards and system controls. |
| H34 Guest gate, H36, H49 profiles | Guest gate and Guest profile scroll. Profile rows wrap. Guest report actions open the account gate. |
| H50–H52 inbox | Loading/empty states, visible errors, network progress and repeated-tap protection added through a view model. |
| Check-in (no wireframe) | Existing roster style retained; each attendance switch names its Player for VoiceOver. |

Visual differences are intentional: SF Pro replaces Inter (D34); standard iOS EventKit owns the Calendar editor; medium sheets expand/scroll at accessibility sizes; segmented controls become menus at those sizes; the long Filters form remains a large sheet; safety explanations omit the V2 blocking behavior.

The reference is the checked-in `Sprint3_Final/WhosDown (Team 6) Sprint 3 – Mapped Wireframes.pdf`. All 32 reference PDF pages have been reviewed; the [45-screen comparison matrix](phase-8-screen-matrix.md) records intentional differences. The simulator audit passed on all 45 screens at default and Accessibility XXXL text sizes. It captured screenshots at both sizes for visual review. Fixed icon/avatar sizes and zero structural gaps are intentional geometry, not spacing exceptions. Feature padding/stack spacing and colors now use design tokens. Status labels retain `StatusBadge`; supporting text uses semantic color tokens. The automated audit checks element accessibility descriptions; it does not replace a manual VoiceOver walk-through.

## Security review

- Reports are authenticated Player create-only writes, with validated targets, reason, 1000-character details limit, server time and open status. No client reads, updates or deletes.
- Cancel, transfer, check-in and waitlist promotion cannot modify unrelated Match/RSVP fields. Transfer validates the new Host name and time window. Check-in requires its Match stamp in the same batch.
- Existing approved Players cannot repeatedly increment the joined count. Leaving requires the corresponding counter update. A waitlist departure requires an existing waitlisted RSVP.
- Inbox read-state updates require a Boolean; chat preview changes cannot add arbitrary fields.
- Storage retains owner-only image writes, signed-in reads and the existing image size/type restrictions. All Storage tests are included in the full rules run.
- Counter writes also reject unknown Match fields.
- There is no server code or production data migration.

## Automated verification

- Swift: **122 tests pass in 31 suites**, with normal simulator signing and a dedicated seeded Firebase emulator. Includes actual Calendar event construction, permission/eligibility rules, reminder planning and live sync, report validation/retry, report persistence through the real repository, scheduler denial/retry/replacement, actual OS pending notifications, and validated tap payloads.
- Simulator UI: **all nine Phase 7 feature tests pass**, including real Calendar save/cancel, Guest/pending/waitlist calendar gates, Match/Player report submission, cancellation rendering, and large-text Host sheets. The delivered-notification cold-launch test passed in two isolated runs and exposed a main-thread crash fix. It intermittently failed to find the notification banner during the combined UI suite; that suite is not fully green.
- Layout audit: **45 screens pass at default and Accessibility XXXL text sizes**, with simulator screenshots captured for both sizes.
- Firebase: **82 tests pass in 13 files**, including all Storage tests and the report/lifecycle regression cases.
- `git diff --check` passes. Node 25 prints engine warnings for the pinned test dependencies, but both suites execute successfully; the documented Node 24 setup remains preferred.

## Acceptance status and remaining owner actions

1. **Core loop passed on two simulators:** Jamie published `Phase8 262db4a1bc`; Taylor discovered it, requested, received approval, opened My Matches and exchanged chat messages with Jamie. Both independent UI tests passed. Scripts: `scripts/run_two_simulator_acceptance.py`. Separate lifecycle checks remain covered by integration/rules tests and the screen audit.
2. Calendar save/cancel and eligibility are exercised by simulator UI tests against the real system editor. Builder tests check times, address and notes. A physical-phone smoke check remains optional release verification.
3. Planner/live-sync/service tests verify approval, time edits, leave/cancel, request contents, replacement/removal and real OS pending requests. A delivered notification was tapped with the app terminated; the simulator cold-launched into the correct Match. A physical locked-phone delivery check remains optional release verification.
4. Optional manual checks: deny notifications on a fresh account and confirm the H14 Settings explanation appears once; sign out and confirm old account reminders are removed. The related denial, retry, and account cleanup code paths have automated coverage.
5. The 45-screen accessibility-size audit passed and screenshots were captured. A manual VoiceOver walk-through (including focus order and spoken labels) remains useful release QA, but is not a failed automated phase requirement.

## Production rules deployment

Firestore rules and indexes were deployed successfully to `whosdown-57e99` on 2026-11-08 using the authorized Firebase account. The CLI confirmed compilation, upload, and release.

Storage rules deployment was attempted but Firebase reports that Storage has not been initialized. The project has billing disabled; the owner must enable the required billing plan and initialize Storage in the Firebase console before these tested rules can be deployed. Billing has not been changed. After initialization, verify the actual default bucket against the app configuration and deploy only Storage rules. Never seed production.

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-08 | Codex | Source audit, lifecycle security fixes, device acceptance steps and deployment hand-off |

| 0.2 | 2026-11-08 | Codex | Finished remaining onboarding, picker, map, Venue, cancellation and notification gaps; added real simulator UI and OS notification acceptance tests |

| 0.3 | 2026-11-08 | Codex | Verified two-simulator core loop; deployed Firestore rules/indexes; documented Storage initialization blocker and exhaustive audit work. |
| 0.4 | 2026-11-09 | Codex | Passed 45-screen audits at default and XXXL text; fixed and verified delivered-notification cold launch; updated acceptance evidence. |
