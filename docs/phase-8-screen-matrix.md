# Phase 8 screen comparison matrix

**Version:** 0.1 · **Last updated:** 2026-11-08

Reference: checked-in Sprint 3 mapped wireframes PDF, all 32 pages reviewed. All screens use SF Pro instead of Inter (D34), four V1 tabs (D46), design tokens, and standard SwiftUI controls (D6). V2-only frames are excluded according to the build plan. The DEBUG audit harness renders the shipping views with deterministic in-memory fixtures; it does not write production data.

| Audit order | Screen / reference | Intentional difference or correction |
|---|---|---|
| 1 | H01 Welcome | Scrollable at accessibility sizes. |
| 2 | H02 Create account | Native form; standard iOS controls (D6). |
| 3 | H41 Sign in | Native form; standard iOS controls (D6). |
| 4 | H34 Guest gate | Large detent at accessibility sizes; account navigation remains in sheet. |
| 5 | H03 Sports | One column at accessibility sizes. |
| 6 | H42 Levels | Levels live here rather than H04 (D46). |
| 7 | H04 Complete profile | Levels moved to H42 (D46). |
| 8 | H05 Permissions | Single notification prompt here (D48); H43 omitted. |
| 9 | H44 Onboarding done | Scrollable completion content. |
| 10 | H06 Discover map | Apple Maps; Match/Host terminology (D13); adaptive Next Up card. |
| 11 | H07 Discover list | Same V1 cards and filters; adaptive Next Up card. |
| 12 | H08 Filters | Large form sheet; PDF frame does not show filter contents, so feature brief governs controls. |
| 13 | H09 Match details | All V1 Matches public (ADR7); media deferred; system calendar editor. |
| 14 | H11 Roster | No V2 friendship/verification badges. |
| 15 | H10 Player profile | Check-in reliability (D37); no V2 feedback/friends. |
| 16 | H12 Join review | Three approval steps; no invented average response time. |
| 17 | H13 Pending | V1 approval status and cancel request. |
| 18 | H14 Joined | System Calendar; Invite friend deferred to V2. |
| 19 | H35 Declined | V1 decline reason and navigation. |
| 20 | H15 Waitlist | Automatic promotion/Host approval (ADR8); no timed offers. |
| 21 | H37 Leave | Shared destructive action above secondary action (1.26). |
| 22 | Cancel request | Uses shared sheet; no separate mapped frame. |
| 23 | H16 Chat | Text only; attachments and unread counts deferred. |
| 24 | H17 Essentials | Optional title; Host counts; no public/private toggle. |
| 25 | H40 Choose location | New Venue questions follow D46. |
| 26 | New Venue | Uses standard form sheet; no separate mapped frame. |
| 27 | H18 Venue details | Media deferred; no invented facility-conflict verification. |
| 28 | H19 Review | V1 summary and publish action. |
| 29 | H45 Created | Manage Match restored; scrollable summary and wrapping chips. |
| 30 | H20 Host dashboard | Includes approved V1 check-in; immediate transfer. |
| 31 | H21 Join requests | Includes waitlist per ADR8. |
| 32 | Decline request | Shared sheet; no separate mapped frame. |
| 33 | H46 Edit Match | Native form for supported V1 fields. |
| 34 | H38 Cancel Match | Reason required by brief; shared action order (1.26). |
| 35 | H22 Transfer host | Transfer Host wording; shared sheet. |
| 36 | Check in | Roster style; named attendance switches; no mapped frame. |
| 37 | H27 My Matches | No V2 group/review summaries. |
| 38 | H28 Past Matches | Attendance data replaces V2 review/social summaries. |
| 39 | H36 Profile | Unsupported favorites/privacy settings deferred; sign-out available. |
| 40 | H49 Edit profile | Native profile form; V1 fields only. |
| 41 | Guest profile | Account gate; no separate mapped frame. |
| 42 | H33 Report | Safety card, reason cards, details; Block remains V2. |
| 43 | H50 Inbox | Six supported V1 notification types; full body wraps. |
| 44 | H51 Update | Multiple field changes and Host note per updated brief. |
| 45 | H52 Cancellation | Cancellation reason and View Match. |

Verification results and outstanding checks are tracked in [the acceptance record](phase-8-audit.md). Automated clipping/description audits complement the visual comparison; they do not establish a full VoiceOver usability certification.

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-08 | Codex | Recorded every V1 screen and reasons for differences from mapped wireframes. |
