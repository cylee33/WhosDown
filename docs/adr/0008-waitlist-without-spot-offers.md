---
Status: accepted
Date: 2026-11-02
Decided by: Chris Lee
---

# Waitlist without 10-minute spot offers

Approved V1 feature 1.17 (Sprint 3 §9.2) said: "first in line gets a 10-minute spot offer when someone leaves; claim spot" (screen H53). We dropped the spot offer. A freed spot is filled by **letting someone in** instead:

- **Open Matches:** the first Player in line joins automatically, in the same transaction as the Player who leaves (or the Host's edit that raises the player limit).
- **Approval-required Matches:** the Host approves anyone from the Join requests or the Waitlist while a spot is free. When a spot opens and people are waiting, the Host gets an in-app notification.

The waiting order is stored as an array of user IDs on the Match (`waitlistIds`). Security rules can't run queries, but they can read an array, so they can check that the Player let in on an Open Match really is first in line.

## Considered Options

- **10-minute spot offer (the Sprint 3 design):** rejected by the owner. Without server code (ADR-0006), expiry could only be handled when someone next opened the Match, and the offer flow added a screen (H53), a notification type, and the hardest security rules in V1.
- **Host approves off the waitlist on every Match:** rejected for Open Matches, where the Host never otherwise has to act; spots would sit empty until the Host noticed.

## Consequences

- H53 "Spot available", the `spotOpen` notification, and the RSVP field `spotOfferExpiresAt` are not in V1. "Spot offer" leaves the glossary.
- A Player let in from the waitlist gets the normal `approved` notification.
- New notification type `spotOpened`, sent to the Host of an Approval-required Match.
- Replaces the spot-offer parts of ADR-0006 ("the waitlist spot offer", "spot-offer expiry") and of plan decision D24.
