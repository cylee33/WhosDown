# Lessons Learned

Problems hit and how they were solved. Newest first. Add an entry whenever something cost more than ~15 minutes.

## 2026-11-01 — Carried over from Sprint 3

- **Firestore test-mode rules expire.** They stop allowing reads and writes about 30 days after the database was created (about Nov 24, 2026 for `whosdown-57e99`). Real security rules must be in place before then.
- **`@DocumentID` needs a document reference to decode.** When decoding Firestore data without a live query (tests, sample data), use `Firestore.Decoder().decode(_:from:in:)` with a reference.
- **Open-Meteo hourly times have no time-zone offset.** Parse them with the response's `utc_offset_seconds`, or the forecast hour is off by several hours.
- **Pin down which source is official.** The Sprint 3 interview notes existed in two versions (a Markdown file and a PDF with extra pages). Confirm the official source before writing from it.
- **Re-read shared files before editing.** Two sessions edited the same Sprint 3 Markdown file at once. Re-read a shared file right before changing it; with git, pull first.
