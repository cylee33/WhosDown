# WhosDown

A mobile app that helps people find, join, and host pickup sports matches nearby.

## Language

### Matches

**Match**:
One pickup sports session at a Venue and time that Players can join.
_Avoid_: Game, activity, event, session

### People

**Player**:
Anyone using WhosDown to find or join Matches.
_Avoid_: User (in product copy), member (reserved for groups)

**Host**:
The Player who created a Match and approves, edits, or cancels it.
_Avoid_: Organizer, owner, creator

**Guest**:
A Player who is browsing without an account; must create an account or sign in before joining, posting, or messaging.
_Avoid_: Anonymous user, visitor

### Places

**Venue**:
A real place where Matches are played, such as a field, court, or gym.
_Avoid_: Location (that is the coordinate), field (too narrow)

### Joining

**RSVP**:
A Player's record for one Match, in any status: pending, approved, declined, waitlisted, or left.
_Avoid_: Reservation, booking, sign-up

**Join request**:
An RSVP that is still pending, waiting for the Host to approve or decline it.
_Avoid_: Application, request (alone)

**Join type**:
Whether a Match is **Open** (Players join instantly) or **Approval required** (the Host approves each Join request).

**Waitlist**:
The ordered queue of Players who want a spot in a full Match.

**Spot offer**:
A time-limited (10-minute) offer of an open spot, given to the first Player on the Waitlist.

**Full**:
A Match whose joined count has reached its player limit; new Players can only join the Waitlist.

### Trust

**Check-in**:
The Host's record of which approved Players actually attended a Match.
_Avoid_: Attendance marking, roll call

**Reliability**:
The share of a Player's checked-in Matches where they attended; it measures showing up, not skill.
_Avoid_: Rating, score

**Skill level**:
A Player's self-chosen level for one sport: Beginner, Casual, All Levels, Intermediate, or Competitive.

**Report**:
A Player's complaint about another Player or a Match, sent for review.

### Releases

**V1 / V2**:
V1 is the first release (the 26 approved features plus approved extras 1.27–1.28); V2 is the final release (features 2.1–2.23 and Private Matches).

---

## Changelog

| Date | Author | Change |
|---|---|---|
| 2026-11-01 | Chris Lee (with Claude) | First terms from the Sprint 3 documents. |
| 2026-11-01 | Chris Lee | Added Match (replaces Game), Host (replaces Organizer), RSVP, Join request. |
| 2026-11-01 | Chris Lee | Added Check-in and Full; Reliability now based on Check-ins; V1/V2 updated for ADR-0007. |
