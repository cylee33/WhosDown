# Contributing to WhosDown

**Version:** 0.1 · **Last updated:** 2026-11-02

How to set up, pick up a feature, and hand it off. Read this before your first commit. One person can work through every lane; three people can work in parallel without blocking each other.

## 1. Read first (15 minutes)

1. [`GLOSSARY.md`](GLOSSARY.md): the words we use (Match, Host, RSVP, Join request…). Use them in code, app text, and docs.
2. [`docs/v1-build-plan.md`](docs/v1-build-plan.md): what V1 is, the lanes, the build phases, and every settled decision (D1, D2…).
3. [`docs/architecture.md`](docs/architecture.md): layers, data model, repository layout, design system.
4. [`docs/adr/`](docs/adr/): why the big decisions were made. Don't reverse one without writing a new ADR.
5. The brief for the feature you take, in [`docs/features/`](docs/features/).

## 2. Set up

> The Xcode project and emulator are created in Phase 0. Until then, this section is the target setup.

**You need:** a Mac with Xcode 27, Node 20 or later, Java 21 or later (for the Firebase emulator), and the Firebase CLI (`npm install -g firebase-tools`).

1. Clone: `git clone https://github.com/cylee33/WhosDown.git`.
2. Open `app/WhosDown.xcodeproj` in Xcode. Swift packages (Firebase, GeoFireUtils) resolve on first open.
3. `GoogleService-Info.plist` is already in the repo (D40). You don't need to download anything from the Firebase console.
4. Start the emulator: from `firebase/`, run `firebase emulators:start`.
5. Seed sample data into the emulator: `node firebase/seed/seed.js` (Pittsburgh Venues, about 10 Matches, 5 test Players; D41). It never touches the real project unless you pass a flag and a key, and the key never goes in git.
6. Run the app on an iOS 26 simulator. Debug builds talk to the emulator; Release builds talk to the real `whosdown-57e99` project.
7. On your own iPhone: sign in to Xcode with a free Apple ID and run. The install expires after 7 days; run again to renew (D36).

**Tests:**

- Domain rules: `swift test` in `app/Packages/WhosDownCore`.
- Security rules: from `firebase/`, run `npm test` with the emulator running.

## 3. Pick up a feature

1. Open the GitHub project board. Each feature (1.1–1.28) is one issue, and each issue links to its brief.
2. Check that everything listed under **Depends on** in the brief is **Done**. If not, pick another feature or ask.
3. Assign the issue to yourself. In the brief, set **Status** to `In progress` and **Owner** to your name, and commit that change (`docs: claim 1.14`). This is how others see the feature is taken.
4. Make a branch from up-to-date `main`: `git checkout main && git pull && git checkout -b feat/1.14-request-to-join`.

Lanes (A Identity & Profile, B Discover & Hosting, C Joining & Lifecycle, Core) are a planned split, not a lock. Anyone can take any feature.

## 4. Build it

- **Follow the brief.** Its acceptance checklist is the definition of done. If the brief is wrong or unclear, fix the brief in the same PR and say so. If the change affects scope or another feature, ask Chris first.
- **Layers:** views → `@Observable` view models → repositories. Views and view models never call Firebase directly. If you think one must, ask first (ADR-0001).
- **Shared code:** models, repository protocols, Firebase repositories, and domain rules live in `WhosDownCore`. Change them only if the brief says to, and keep the change small. Core changes need Chris's review.
- **Domain rules test-first:** write the failing test in `WhosDownCoreTests`, then the code (D28).
- **Security rules:** if your feature writes something new, add the rule and an emulator test in `firebase/` in the same PR.
- **Screens:** match the Figma wireframe named in the brief (layout, wording, colors, spacing on the 8-point grid). Use the system font (SF Pro), light mode only (D34, D35). Wireframe text says "game"; app text says **Match** (D13).
- **New files:** add them in the feature's folder. Xcode synchronized folders mean you don't edit the project file.
- **Extras:** nothing beyond the brief without Chris's approval (ADR-0003).

## 5. Hand off (every PR, even unfinished work)

Before you open a PR, or stop for the day on a branch someone else may continue, update the brief's **Hand-off note**:

- What works now.
- What is left, in order.
- Anything surprising (a gotcha, a workaround, a test that is skipped and why).
- The exact next step, so the next person can start without asking.

Also tick the acceptance boxes that now pass, and add a changelog row to the brief.

## 6. Pull requests

- **Title:** `1.14 Request to join: <what this PR does>`.
- **Template** (filled in automatically): feature number, screens (H-numbers), brief updated (yes/no), how you tested, screenshots for UI.
- **Size:** one feature per PR. Split large features into several PRs; the brief's hand-off note tracks progress between them.
- **Review:** one teammate approves, then **squash merge**. Until branch protection is on (around 2026-11-04, D14), Chris may self-merge while building alone; everyone else waits for an approval.
- When the feature's last PR merges, set the brief's **Status** to `Done` and close the issue.

## 7. Commits and docs

- Commit messages: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, plus a short description.
- Living docs (plan, architecture, briefs, this file) carry a version and a changelog. Bump the version and add a row whenever you change them. Rules: [`docs/README.md`](docs/README.md).
- New hard-to-reverse decision? Write an ADR in `docs/adr/`.
- New term? Add it to `GLOSSARY.md`.
- Hit a problem that cost you time? Add it to [`docs/lessons-learned.md`](docs/lessons-learned.md).
- Always `git pull` before editing shared docs; re-read the file before you edit it.

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-02 | Chris Lee (with Claude) | First version: setup, claiming, building, hand-off, PRs |
