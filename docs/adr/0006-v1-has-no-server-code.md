---
Status: accepted
Date: 2026-11-01
Decided by: Chris Lee
---

# V1 has no server code: the app writes shared data in transactions, guarded by strict security rules

In V1, every change to shared data — joining, approving, leaving, the waitlist spot offer, and writing notifications into another Player's inbox — is made by the app in a single Firestore transaction. Firestore security rules decide who may write what (for example, only the Match's Host may approve a Join request). Spot-offer expiry is checked when someone next opens the Match. This keeps V1 on the free Spark plan with no new tooling.

## Considered Options

- **Cloud Functions in V1**: safer, because the server enforces the rules, but it needs the pay-as-you-go plan and new tooling for the team. Deferred to V2, where push notifications need Cloud Functions anyway.

## Consequences

- Security rules carry the weight that server code would; they need their own tests before the Nov 24 test-mode expiry.
- When V2 adds Cloud Functions, some of these client-side writes (notifications, spot-offer expiry) should move to the server.
