# Phase 7–8 simulator sanity checks

**Version:** 0.1 · **Last updated:** 2026-11-08

Use the seeded demo Firebase emulator and a normally signed Debug simulator build. Production must never be seeded. Alex is approved for Pickleball Doubles; Jamie hosts it. Use a future Match for Calendar/reminder checks. The automated test target exercises the system Calendar editor and real repositories.

## 1.23 Add to calendar

1. Sign in as an approved Player, open the future Match from My Matches, and tap Add to calendar. Check title, start/end, Venue address and Match ID in notes. Cancel: return to the Match without saving.
2. Open the editor again and save. Confirm the event in Calendar. Repeat as the Host using the Match menu.
3. Open a Match as Guest, pending requester and waitlisted Player. Calendar must be unavailable. Repeat with a started/cancelled Match.

## 1.24 Match reminders

1. On a fresh install/account, allow notifications in H05. Join a future Match as an approved Player. The scheduler should create one reminder for one hour before start; returning to the app must not duplicate it.
2. Change the Match start time as Host; foreground the Player app. The pending reminder must move. Leave/cancel the Match, foreground, and confirm removal. Sign out: old account pending reminders must disappear.
3. Deny notifications during onboarding. The app must not show another system permission prompt. H14 explains Settings once for that account. Reopen H14 and confirm it does not repeatedly interrupt.
4. For accelerated OS delivery use `ReminderDeliveryTests`; its DEBUG probe schedules a real reminder after 15 seconds without changing backend Match data. Delivery and cold-tap verification results are recorded separately in the acceptance record.

## 1.25 Report a Player or Match

1. From Match details choose Report. Select each reason; Submit stays unavailable until a reason is selected. Enter optional details, submit, and verify the success confirmation.
2. Open a roster Player, choose Report, and submit. Confirm it targets that Player with Match context. A normal client must not be able to read submitted reports.
3. Try as Guest: the account gate appears. At Accessibility XXXL, scroll through reasons/details/actions; no required control may become unreachable. Disconnect the emulator before submitting: a clear error remains and retry works after reconnecting.

## 1.26 Layout and interaction

1. At default and largest accessibility text size, open Discover map/list, Match details, My Matches, Profile and Inbox. Long labels wrap; icon buttons have meaningful VoiceOver labels; screens scroll.
2. Open join, leave, cancel-request, decline, cancel-Match, transfer, Guest and Filters sheets. Verify drag handle, explanation, primary action above secondary action, scrolling and large-size expansion. Slow network operations show progress and prevent double submission.
3. Publish a Match. The completion screen must offer Manage Match and Back to Discover. Manage opens its dashboard. Use two simulators to publish → discover → request → approve → My Matches → exchange chat messages.
4. Run the exhaustive fixture audit after building for testing: `python3 scripts/run_screen_audit.py`. It captures top/bottom screenshots for 45 shipping V1 screens at both text sizes and checks accessibility descriptions/clipping. See the screen matrix for intended wireframe differences.

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-08 | Codex | Repeatable simulator checks for all four Phase 7/8 features. |
