---
Status: accepted
Date: 2026-11-01
Decided by: Chris Lee
---

# SwiftUI views, @Observable view models, and a repository layer that owns all backend calls

WhosDown is a native iOS app built with SwiftUI. Each screen gets its data from an `@Observable` view model, and view models get data only from repositories (one per domain, such as games or RSVPs). Views and view models never call Firestore directly; any case where that seems necessary must be raised with the team before it is written.

We chose this over views calling Firestore directly because three people will add features in parallel: one data layer keeps backend code in one place, keeps each feature folder independent, and lets join / approve / waitlist rules be tested without a running backend.
