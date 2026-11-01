---
Status: accepted
Date: 2026-11-01
Decided by: Chris Lee
---

# Firebase is the backend, using the existing `whosdown-57e99` project

WhosDown uses Firebase (Auth, Cloud Firestore, Storage; Cloud Messaging in V2) through the existing project `whosdown-57e99`. Firestore's live listeners fit chat and RSVP status, and anonymous accounts that link to an email account match the Guest flow (H01, H34). The Sprint 3 schema, data mapping, and the TA's viewer access are all built on this project. Its weak spots have known fixes: geohash ranges for radius search, and transactions for counters.

## Considered Options

- **Supabase**: real geographic queries (PostGIS), but free projects pause after a week of inactivity, and the schema and data mapping would have to be redone.
- **AWS Amplify**: the most setup (Cognito, AppSync, DynamoDB) and the weakest Swift tooling for a class timeline.
- **CloudKit**: needs the paid Apple Developer Program, has weak queries on public data, and no easy console for the TA.

## Consequences

- Real security rules must replace test-mode rules before they expire (~Nov 24, 2026).
- V2 push notifications need Cloud Functions, which needs the pay-as-you-go (Blaze) plan with a card on file.
