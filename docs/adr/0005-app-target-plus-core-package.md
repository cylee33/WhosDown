---
Status: superseded by ADR-0009
Date: 2026-11-01
Decided by: Chris Lee
---

# One app target with feature folders, plus a local `WhosDownCore` Swift package

The Xcode project has one app target whose code is split into feature folders (Onboarding, Discover, Match, Host, Profile, Notifications), and a local Swift package, `WhosDownCore`, that holds the domain models, repository protocols, Firebase repositories, and the domain rules (joining, waitlist, counters). Security rules, indexes, and seed data live in a top-level `firebase/` folder.

We split the core into a package so its rules can be tested without the app, and so every feature depends on the same core in the same way while three people work in parallel. Feature folders use Xcode's synchronized folders, so adding a file does not edit the project file — the usual source of Xcode merge conflicts. We rejected one package per feature: more setup than a three-person team needs.
