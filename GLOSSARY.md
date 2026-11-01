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
A real place where games are played, such as a field, court, or gym.
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

### Trust

**Reliability**:
The share of a Player's RSVPs where they actually attended; it measures showing up, not skill.
_Avoid_: Rating, score

**Skill level**:
A Player's self-chosen level for one sport: Beginner, Casual, All Levels, Intermediate, or Competitive.

**Report**:
A Player's complaint about another Player or a Match, sent for review.

### Releases

**V1 / V2**:
V1 is the first release (the 26 approved features); V2 is the final release (features 2.1–2.23).

---

## Changelog

| Date | Author | Change |
|---|---|---|
| 2026-11-01 | Chris Lee (with Claude) | First terms from the Sprint 3 documents. |
| 2026-11-01 | Chris Lee | Added Match (replaces Game), Host (replaces Organizer), RSVP, Join request. |
