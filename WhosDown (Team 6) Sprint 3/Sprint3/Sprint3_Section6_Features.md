# 6. List of Features

Version 1 (Sprint 4) is the core loop a player and a host need: sign up, find a game on the map, see its details and weather, join it (open or with host approval), host and manage a game, and talk in the game chat. Everything social or reputation-based moves to Version 2 (final sprint), because it builds on data that only exists once V1 is in use (attendance, past games, friends).

[TEAM: add one or two sentences here on what the prototype user tests showed about priorities, e.g. which flows testers went to first and which features they called nice-to-have.]

Screen IDs refer to the hi-fi wireframes (H01–H63).

## Version 1 — Sprint 4

| # | Feature | Screens | Data |
|---|---|---|---|
| V1-1 | Email sign-up and sign-in, password reset | H01, H02, H41 | Auth, `users`, `private/settings` |
| V1-2 | Guest browsing; sign-in prompt when a guest tries to join | H01, H34 | Auth (anonymous), `AppUser.isGuest` |
| V1-3 | Onboarding: choose sports, set skill level per sport, play style, bio, home area | H03, H04, H42, H44 | `users.sportLevels`, `playStyles`, `bio`, `homeArea` |
| V1-4 | Location permission and user location on map | H05 | Core Location |
| V1-5 | Discover map with sport pins, visible search radius, "Next up" card | H06 | `games` geohash query, MapKit |
| V1-6 | Discover list view with map/list toggle | H07 | `games` |
| V1-7 | Filters: sport, time, distance (manual miles), skill, join type | H08 | `games` query + `searchRadiusMiles` |
| V1-8 | Game detail: badges, time, venue, distance, players count, organizer summary | H09 | `games`, `users/{hostId}` |
| V1-9 | Weather line for outdoor games | H09, H14, H18 | Open-Meteo |
| V1-10 | Player roster | H11 | `games/{id}/rsvps` |
| V1-11 | Join an open game instantly | H12, H14 | `rsvps` (approved), `joinedCount` |
| V1-12 | Request to join an approval game, with note to host | H12, H13 | `rsvps` (pending), `noteToHost` |
| V1-13 | Join states: Pending, Approved, Declined (with host message), Full | H13, H14, H15, H35 | `RSVP.status`, `hostResponse` |
| V1-14 | Leave a game / cancel a request | H13, H37 | `RSVP.status = left` |
| V1-15 | Create a game: sport, date/time, location, skill, limit, join type, visibility, free/paid label | H17, H40, H18, H19, H45 | new `games` doc, `venues` |
| V1-16 | Venue search and selection (MapKit + saved venues) | H40 | MapKit, `venues` |
| V1-17 | Host dashboard: requests count, chat, edit, cancel | H20 | `games`, `conversations` |
| V1-18 | Approve / decline join requests | H21 | `RSVP.status`, counts |
| V1-19 | Edit a game | H46 | `games` update |
| V1-20 | Cancel a game (with reason) | H38 | `games.status`, `cancelReason` |
| V1-21 | Game chat (real-time) | H16 | `conversations`, `messages` |
| V1-22 | My Games: Upcoming and Hosting tabs | H27 | `rsvps` collection group, `games` |
| V1-23 | In-app notifications list for approvals, declines, changes, cancellations | H31, H50, H51, H52 | `users/{me}/notifications` |
| V1-24 | View own and other players' profiles (bio, sports, level, games played) | H10, H36 | `users` |
| V1-25 | Edit profile and photo | H49 | `users`, Storage |

**V1 is done when** a host on one device can create an approval game and a player on another device can find it on the map, request to join, get approved, see it in My Games, and message in its chat, with all data coming from Firestore.

## Version 2 — Final sprint

| # | Feature | Screens | Why V2 |
|---|---|---|---|
| V2-1 | Push notifications (FCM) and notification preferences | H32, H43 | Needs APNs setup; V1 has the in-app list |
| V2-2 | Saved "new game near me" alert | H08, H32 | Needs push + a Cloud Function to match new games |
| V2-3 | Waitlist: join, position, 10-minute spot offer, claim | H15, H53 | Builds on V1 join flow |
| V2-4 | Transfer host | H22 | Edge case of host flow |
| V2-5 | Friends: requests, friend list, friends' activity, people you may know | H10, H23 | Needs a user base |
| V2-6 | Direct messages | H24, H39 | Reuses V1 chat code |
| V2-7 | Groups: discover, detail, join, create, group chat, group games | H25, H26, H47, H55 | Separate object type |
| V2-8 | Past games and game summary, personal notes | H28, H29 | Needs completed games |
| V2-9 | Post-game reviews: MVP, play again, feedback tags | H30, H60–H63 | Needs completed games |
| V2-10 | Reliability score and reputation page | H10, H11, H58 | Needs attendance data |
| V2-11 | Report and block users | H33, H57 | Safety layer |
| V2-12 | Privacy settings | H57 | Depends on friends |
| V2-13 | Favorite fields | H56 | Convenience |
| V2-14 | Global search (games, groups, people) | H48 | V1 has filters |
| V2-15 | Game photos and clips | H09, H18 | Storage uploads |
| V2-16 | Add to Calendar, invite a friend | H14 | Convenience |
| V2-17 | Account & security: change password, Apple/Google sign-in, delete account | H59 | Account management |
| V2-18 | Custom sports | H03, H17 | Small extension |
| V2-19 | Real payments for paid games | H12, H17 | Out of scope; V1 only labels a game as free or paid |

## Sprint 4 schedule (weekly)

Dates assume Sprint 4 runs three weeks, Oct 27 – Nov 16. Update them to match Canvas if needed. Owners are a proposed split.

| Week | Goal | Features | Owner |
|---|---|---|---|
| **Week 1** (Oct 27 – Nov 2) | Project setup and data layer | Xcode project with Firebase; `Models.swift` and repositories for `users`, `games`, `rsvps`, `venues`; Firestore security rules; seed data | All |
| | Accounts and onboarding | V1-1, V1-2, V1-3, V1-4 | Kurt |
| | Discover (read-only) | V1-5, V1-6 using seed games | Chris |
| | Game detail (read-only) | V1-8, V1-9, V1-10 | Jaimin |
| **Week 2** (Nov 3 – Nov 9) | Joining | V1-11, V1-12, V1-13, V1-14 | Jaimin |
| | Hosting | V1-15, V1-16, V1-17 | Chris |
| | Filters and My Games | V1-7, V1-22 | Kurt |
| | **Check:** full join flow works on two simulators | | All |
| **Week 3** (Nov 10 – Nov 16) | Host controls | V1-18, V1-19, V1-20 | Chris |
| | Chat | V1-21 | Jaimin |
| | Notifications and profiles | V1-23, V1-24, V1-25 | Kurt |
| | Testing, bug fixes, demo run-through | Unit tests for view models and decoding; fix issues | All |

## Final sprint schedule (V2)

| Week | Features |
|---|---|
| Week 1 | V2-3 waitlist, V2-4 transfer host, V2-8 past games, V2-9 reviews, V2-10 reliability |
| Week 2 | V2-5 friends, V2-6 direct messages, V2-7 groups, V2-11 report/block, V2-12 privacy |
| Week 3 | V2-1 push, V2-2 alerts, V2-13 favorites, V2-14 search, V2-15 media, V2-16 calendar/invite, V2-17 account, V2-18 custom sports; polish and final testing |

V2-19 (real payments) is not planned for this course.
