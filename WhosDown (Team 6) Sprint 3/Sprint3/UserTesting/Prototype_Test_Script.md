# WhosDown — Prototype User Test Script

**Prototype:** Figma, page "03 — Hi-Fi Full Marks", flow "WhosDown Hi-Fi — Full User Flow" (starts at H01 Welcome)
https://www.figma.com/proto/4dTTJVikeBUzFTG9KnSowN/Who-sDown-%E2%80%94-Lo-fi-Wireframes?node-id=104-23&starting-point-node-id=104%3A23&scaling=min-zoom&content-scaling=fixed&page-id=104%3A16

**Session length:** about 25 minutes
**Team roles:** one **facilitator** (reads the script, gives tasks) and one **note-taker** (fills in the note sheet at the end). The third teammate can run a second session at the same time.
**Who to test:** at least 4 people who play or want to play pickup sports (CMU students are fine). Use people who did **not** test the Sprint 2 wireframes if you can.

---

## Before the session

- [ ] Open the prototype link on a phone (best) or in Figma presentation view at phone size. Start on H01.
- [ ] Press **R** in presentation view between participants to restart the flow at H01.
- [ ] Print or open a copy of the note sheet (end of this file) for each participant.
- [ ] Have a timer ready.
- [ ] Ask whether you may take notes (and record audio, if you want to). Do not record without a yes.

## Intro (read aloud, about 2 minutes)

> Thanks for helping. We're building WhosDown, an app for finding and organizing pickup sports games.
>
> This is a clickable prototype, not the real app. Some buttons won't do anything, and nothing you type is saved. That's fine.
>
> We're testing the app, not you. There are no wrong answers. If something is confusing, that's exactly what we need to know.
>
> Please **think out loud** as you go: say what you're looking at, what you expect to happen, and what surprises you.
>
> I may not answer questions during a task, because we want to see what you'd do alone. I'll answer everything at the end.

## Warm-up questions (about 2 minutes)

1. Which sports do you play, and how often?
2. How do you find pickup games now (group chats, friends, showing up, apps)?
3. What's the most annoying part of organizing or joining a game today?

---

## Tasks (about 15 minutes)

Read each task as written. Do **not** name buttons or screens. Start the timer when you finish reading; stop it when they reach the end screen or give up.

For each task, the note-taker records: **Success** (did it alone), **Assisted** (needed a hint), or **Failed**, plus time and anything they said.

| # | Task (read aloud) | Expected path | Done when they reach |
|---|---|---|---|
| T1 | "You just downloaded WhosDown. Set up an account for yourself." | H01 → H02 → H03 → H42 → H04 → H05 → H43 → H44 | H44 "You're all set" |
| T2 | "Find a soccer game happening **tonight** within **3 miles**. Look at the options as a list instead of a map." | H06 → H07 → H08 (filters) → H07 | H07 with filters applied |
| T3 | "Open the **Pickup Soccer** game. Before deciding to go, find out: what the weather will be, who's organizing it and whether they're reliable, and who else is going." | H07 → H09 → H10 → back → H11 | Has seen H09, H10, H11 |
| T4 | "You want to play. Ask to join, and tell the host you're new to the group." | H09 → H12 → H13 | H13 "Pending" |
| T5 | "Later, the host approved you. Find the game in your games, open the group chat, then decide you can't make it and leave the game." | H06 → H27 → H14 → H16 → back → H37 | H37 confirmation |
| T6 | "Now you want to **host** your own game: soccer, tonight, 7:00–8:30, at the CMU Soccer Field, 14 players, approval required. Publish it." | H17 → H40 → H18 → H19 → H45 | H45 "Game created" |
| T7 | "Two people have asked to join your game. Approve one of them. Then change the game's start time." | H45 → H20 → H21 → back → H20 → H46 | H46 Edit game |
| T8 | "You played a game last month. Find it and leave feedback on the people you played with, including who was the MVP." | H27 → H28 → H29 → H60 → H61 → H62 | H62 "Reviews ready" |

**Optional, if time allows**

| # | Task | Expected path |
|---|---|---|
| T9 | "Your friend Mina is playing tonight. Find what she's doing and send her a message." | H06 → H23 → H10 or H24 → H39 |
| T10 | "Turn off notifications for new nearby games, then look at your recent notifications." | H36 → H32 → H31 → H50 |

**Hints, if someone is stuck for about 60 seconds:** first ask "What are you looking for?" If still stuck, point to the general area ("try the bottom bar"). Mark the task **Assisted**.

### Hidden paths the facilitator should know

All 63 hi-fi screens are reachable from H01.

- **Guest:** tapping "Explore as guest" on H01 marks the session as a guest. Then "Request to join" on any game opens the Guest Join Gate (H34) instead of H12. Restart the prototype (press **R**) before the next participant so the guest flag resets.
- **Declined:** on H13 Pending, tapping the **PENDING** badge shows the Declined Request screen (H35), which simulates the host saying no.
- **Single review:** on H28 Past Games, tapping the **REVIEW** badge on the first game opens the one-player Post-game Review (H30). Tapping the row itself opens the game summary (H29) as before.

### Known prototype limits (do not count against the participant)

- Join is approval-only in the prototype; there is no instant-join path from H12.
- Typing in text fields does nothing; tapping the field is enough.

### Optional guest task

| # | Task | Expected path |
|---|---|---|
| T11 | (Restart first.) "Look around the app without making an account, then try to join a game." | H01 → Explore as guest → H06 → H09 → H34 |

---

## Follow-up questions (about 5 minutes)

Ask after all tasks.

1. On a scale of 1–5, how easy was it to **find and join a game**? Why?
2. On a scale of 1–5, how easy was it to **host and manage a game**? Why?
3. Was anything confusing, or did anything work differently from what you expected?
4. Before joining a game, what information mattered most to you? Was anything missing?
5. How did you feel about the **reliability** score and the post-game **feedback / MVP**? Would you use them? Would anything make you uncomfortable?
6. Which features would you need on day one, and which could come later? (Show the list: map, filters, join requests, game chat, friends, groups, reviews, notifications, waitlist.)
7. Would you use WhosDown instead of what you use now? What would stop you?
8. Anything else you'd change?

## Wrap-up

> Thank you, this really helps. Do you have any questions for us?

Answer any questions they held back during the tasks.

---

## Note sheet (one per participant)

**Participant:** P__  **Date/time:** ______  **Facilitator:** ______  **Note-taker:** ______
**Device:** phone / laptop  **Plays:** ______________  **Finds games via:** ______________

| Task | Result (S / A / F) | Time | Where they hesitated or went wrong | Quotes |
|---|---|---|---|---|
| T1 Onboarding | | | | |
| T2 Find + filter | | | | |
| T3 Evaluate game | | | | |
| T4 Request to join | | | | |
| T5 My Games, chat, leave | | | | |
| T6 Host a game | | | | |
| T7 Approve + edit | | | | |
| T8 Post-game review | | | | |
| T9 Friends + message (opt.) | | | | |
| T10 Notifications (opt.) | | | | |

**Follow-up answers**

1. Find/join ease (1–5): __ because ______
2. Host/manage ease (1–5): __ because ______
3. Confusing / unexpected: ______
4. Info that mattered / missing: ______
5. Reliability + feedback/MVP: ______
6. Day one vs later: ______
7. Would switch? What stops them: ______
8. Other: ______

**Top 3 observations (note-taker, right after the session)**

1.
2.
3.
