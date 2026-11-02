# Seed data (emulator only)

`npm run seed` (from `firebase/`, with `npm run emulators` running in another terminal) fills the local emulator. It refuses to run against anything but a local emulator (D41).

## Test Players

Password for all: `whosdown123`

| Email | Name | Notes |
|---|---|---|
| alex@whosdown.test | Alex Morgan | Joined Pickup Soccer and 7v7; declined from Basketball Run; hosts Sunday Tennis and Pickleball |
| jamie@whosdown.test | Jamie Morales | Hosts Pickup Soccer (1 Join request), 7v7 (Full, 1 waitlisted), and the past Sunday 7v7 (checked in) |
| mina@whosdown.test | Mina Kim | Hosts Beginner Kickabout and Indoor Volleyball; marked not attended in the past Sunday 7v7 |
| taylor@whosdown.test | Taylor Ross | Pending on Pickup Soccer; waitlisted on 7v7; hosts Ultimate and the cancelled Spikeball |
| sam@whosdown.test | Sam Lee | Hosts Basketball Run (Approval required, $5) |

## What the 10 Matches cover

Open and Approval required; free and paid; Full with a waitlist; a pending Join request; a declined RSVP with a Host message; a past Match with Check-in; a cancelled Match with a custom sport; indoor and outdoor; times from a few hours ago to four days out (relative to when you seed).

Running the seed again resets the same documents and moves the times relative to now.
