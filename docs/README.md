# WhosDown Documentation

How the team's documentation is organized, and how it is versioned.

| Document | What it holds | How it changes |
|---|---|---|
| [`../GLOSSARY.md`](../GLOSSARY.md) | The project's words: what a Game, RSVP, Waitlist, etc. mean. No implementation details. | Living. Edit when a term is settled; note it in the changelog at the bottom. |
| [`adr/`](adr/) | Architecture Decision Records: one file per hard-to-reverse decision, with the reason. | **Append-only.** Never rewrite an accepted ADR. To change a decision, write a new ADR and mark the old one `superseded by ADR-NNNN`. |
| [`v1-build-plan.md`](v1-build-plan.md) | V1 goal, feature list, build order, phases, timeline, open questions. | Living. Bump the version and add a changelog row on every change. |
| [`architecture.md`](architecture.md) | Blueprint: layers, modules, data flow, repo layout. | Living. Bump the version and add a changelog row on every change. |
| [`lessons-learned.md`](lessons-learned.md) | Problems hit and how they were solved, so nobody repeats them. | Append-only log, newest first. |

## Versioning rules

1. **Living docs** (`v1-build-plan.md`, `architecture.md`) carry a `Version` and `Last updated` line at the top and a **Changelog** table at the bottom.
   - Minor change (wording, one item added): `0.1 → 0.2`.
   - Major change (scope, order, or structure changes): `0.x → 1.0`, `1.x → 2.0`.
   - Every changelog row names the author, so teammates know who to ask.
2. **ADRs** are numbered `0001-slug.md`, `0002-slug.md`, … and never edited after they are accepted, except to change their `Status`.
3. **Git** is the full history. Doc changes go in their own commits with a `docs:` prefix (for example `docs: plan v0.3 — add build order`).

## Source material (Sprint 1–3 history)

| What | Where |
|---|---|
| Idea and problem statement | `IdeaDocs/Project Ideation.pdf` |
| Sprint 1: 10 questions, competitors (GoodRec, Meetup), first interviews | `IdeaDocs/WhosDown(Team 6) Sprint 1 (1).pdf` |
| Sprint 2 assignment (wireframes, user testing) | `IdeaDocs/Sprint 2.pdf` |
| Sprint 3 final document: Firebase schema, Swift structs, Open-Meteo, data mapping (reads R1–R19, writes W1–W19), V1/V2 feature list | `WhosDown (Team 6) Sprint 3/Sprint3_Final/WhosDown (Team 6) Sprint 3.pdf` |
| 63 hi-fi wireframes (H01–H63) with data badges and V1/V2 tags | `WhosDown (Team 6) Sprint 3/Sprint3_Final/WhosDown (Team 6) Sprint 3 – Mapped Wireframes.pdf`; Figma file `4dTTJVikeBUzFTG9KnSowN`, pages "03 — Hi-Fi Full Marks" and "05 — Sprint 3 Data Mapping" |
| Sprint 3 user testing (4 participants, 23 lessons) | `WhosDown (Team 6) Sprint 3/Sprint3_Final/WhosDown (Team 6) Sprint 3 – User Interviews Report.pdf`; raw notes `IdeaDocs/User Testing Sprint 3.pdf` |
| Sprint 3 rubric self-assessment | `IdeaDocs/Sprint 3 Rubric Self-Assessment.pdf` |
| Sprint 3 test code (reference only, see ADR-0002) | `WhosDown (Team 6) Sprint 3/Sprint3/WhosDownDataCheck/`, `.../Sprint3_Version2/Code/` |
