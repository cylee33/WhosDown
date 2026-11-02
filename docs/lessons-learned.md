# Lessons Learned

Problems hit and how they were solved. Newest first. Add an entry whenever something cost more than ~15 minutes.

## 2026-11-02 — Phase 1

- **iCloud Drive makes " 2" copies inside the repo.** The repo lives on the Desktop, which syncs to iCloud. When files change quickly, iCloud can leave conflict copies such as `OnboardingViewModel 2.swift`. Xcode's synchronized folders then compile both, and the build fails with "invalid redeclaration". Fix: compare the copy with the real file (`diff`), then delete the copy. To avoid it, keep the repo outside iCloud-synced folders, for example `~/Developer/WhosDown`.
- **Firebase sign-in survives deleting the app.** Firebase Auth stores the session in the iOS Keychain, which isn't wiped on uninstall. A reinstalled app came back signed in as the last account. Fix in `Session.start()`: sign out once when a UserDefaults flag (wiped on uninstall) is missing. Tests that build a `Session` pass `defaults: .launchedBefore`.
- **Nested `#require` doesn't compile.** `try #require(f(try #require(x)))` fails with "recursive expansion of macro". Unwrap in two lines.

## 2026-11-02 — Phase 0 setup

- **GeoFireUtils doesn't support Firebase 13.** Its `Package.swift` caps Firebase below 12 (release 5.0.1) or 13 (main branch), so SPM can't resolve it with `firebase-ios-sdk` 13.x. We port the small geohash part instead (D50).
- **The Firestore emulator needs Java 21.** `brew install openjdk@21` installs it "keg-only", so `java` isn't on the PATH until you add `/opt/homebrew/opt/openjdk@21/bin` (CONTRIBUTING §2).
- **Use a `demo-` project ID for local work.** The emulator, seed script, rules tests, and Debug app all use `demo-whosdown`. Firebase treats `demo-*` IDs as offline-only, so nothing can reach the real project by mistake.
- **`@DocumentID` doesn't fit Xcode 27's concurrency defaults.** With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, data models must be `nonisolated` (or their `Codable` conformance only works on the main actor), and `@DocumentID`'s wrapper isn't `Sendable`. Models keep a plain `var id: String?`; repositories decode with `snapshot.decoded(as:)` (`Models/Repositories/FirestoreDocument.swift`), which fills in the document ID. This also replaces the Sprint 3 `decode(_:from:in:)` workaround below.
- **"The iOS 27.0 simulator runtime is not available."** After an Xcode update, CoreSimulator can be stale. Test on an iOS 26.5 simulator (our minimum anyway) or reinstall the runtime in Xcode Settings → Components.
- **Xcode 27's default Swift settings live in its templates.** `/Applications/Xcode.app/Contents/Developer/Library/Xcode/Templates/Project Templates/Base/*/TemplateInfo.plist`. Read them there instead of guessing (architecture §4).

## 2026-11-01 — Carried over from Sprint 3

- **Firestore test-mode rules expire.** They stop allowing reads and writes about 30 days after the database was created (about Nov 24, 2026 for `whosdown-57e99`). Real security rules must be in place before then.
- **`@DocumentID` needs a document reference to decode.** When decoding Firestore data without a live query (tests, sample data), use `Firestore.Decoder().decode(_:from:in:)` with a reference.
- **Open-Meteo hourly times have no time-zone offset.** Parse them with the response's `utc_offset_seconds`, or the forecast hour is off by several hours.
- **Pin down which source is official.** The Sprint 3 interview notes existed in two versions (a Markdown file and a PDF with extra pages). Confirm the official source before writing from it.
- **Re-read shared files before editing.** Two sessions edited the same Sprint 3 Markdown file at once. Re-read a shared file right before changing it; with git, pull first.
