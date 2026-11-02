---
Status: accepted
Date: 2026-11-02
Decided by: Chris Lee
Supersedes: ADR-0005
---

# Code organized strictly as MVVM in three top-level folders: Models, Views, ViewModels

The app target's code lives in three top-level folders, one per MVVM layer. (MVC's "Controllers" are the ViewModels here: SwiftUI has no view controllers, and ADR-0001 already chose `@Observable` view models.)

```
app/WhosDown/
├── App/          entry point, tab bar, dependency setup
├── Models/       Data/ (structs, enums), Repositories/ (the only Firebase access), Services/ (weather, location, calendar, reminders), Rules/ (domain rules), Fakes/ (in-memory repositories)
├── Views/        DesignSystem/ + one subfolder per area: Onboarding, Discover, Match, Host, Profile, Notifications
└── ViewModels/   one subfolder per area, same names as Views/
app/WhosDownTests/   domain-rule and view-model tests
```

The area subfolders inside Views/ and ViewModels/ keep the three lanes apart, so parallel work still rarely touches the same files. All folders are Xcode synchronized folders, so adding a file doesn't edit the project file.

## Considered Options

- **Feature folders + a `WhosDownCore` Swift package (ADR-0005):** replaced at the owner's request for a strict, recognizable MVVM layout.
- **Models as a separate Swift package, Views and ViewModels in the app:** faster `swift test` runs for domain rules, but two places to look and not the three-folder structure the owner asked for.
- **Models/Views/ViewModels inside each feature folder:** splits shared models across features.

## Consequences

- No local Swift package. Domain rules are tested in the `WhosDownTests` target (`xcodebuild test`), which builds the app first; slower than `swift test` but one project.
- Paths in every feature brief's "Files to touch" use the new layout.
- Views and ViewModels still never call Firebase; only `Models/Repositories/` does (ADR-0001).
