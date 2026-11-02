---
Status: accepted
Date: 2026-11-01
Decided by: Chris Lee
---

# V1 scope changes: add Host check-in and Transfer host; move Private Matches to V2

Approved by the owner under [ADR-0003](0003-v1-scope-is-the-approved-feature-list.md):

- **Added 1.27 Host check-in.** V1 shows Reliability on H10, H11, H21, and H36, but recording attendance was a V2 feature (2.7). Without check-in, Reliability would have no real data in V1, so the Host's check-in moves into V1. The rest of 2.7 (feedback tags, MVP count, response time) stays in V2.
- **Added 1.28 Transfer host** (was V2 2.14). A Host cannot leave their own Match; they either cancel it or transfer it to a joined Player.
- **Removed Private Matches from V1.** Invites (2.15) and share links (2.22) are V2, so a Private Match could not be found or joined in V1. Every V1 Match is public; the Public/Private choice returns in V2 together with invites.
