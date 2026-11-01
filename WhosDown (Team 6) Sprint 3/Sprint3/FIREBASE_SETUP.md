# Remaining steps (need a person)

## 1. Create the Firebase project (about 5 minutes)

1. Go to https://console.firebase.google.com and click **Create a project**. Name it `WhosDown`. Google Analytics is not needed.
2. Left menu: **Build → Firestore Database → Create database**. Pick a location (`nam5 (us-central)` is fine) and choose **Start in test mode**. Test mode lets the check app write the seed data. Tighten the rules before Sprint 4 ends.
3. Project overview → **Add app → iOS**. Bundle ID: `edu.cmu.whosdown.datacheck`. Download `GoogleService-Info.plist`. Skip the remaining wizard steps.
4. Put the plist here: `Sprint3/WhosDownDataCheck/WhosDownDataCheck/GoogleService-Info.plist`.

Then tell Claude. It rebuilds the app, presses **Seed sample data** on the Firestore tab in the simulator, and saves `Screenshots/04_firestore_readback.png`.

## 2. Firebase console screenshots

After seeding, in the console under **Firestore Database → Data**, take a screenshot of each top-level collection with one document open:
`users`, `venues`, `games` (also open `gm_7d2k → rsvps`), `groups`, `conversations` (also open `c_gm_7d2k → messages`), `reviews`, `reports`.

Save them as `Screenshots/03_firestore_console_<collection>.png`. The rubric also accepts giving the TA access to the project instead (Project settings → Users and permissions → Add member, role **Viewer**).

## 3. Playground screenshot

1. Open `Sprint3/WhosDownWeather.playground` in Xcode.
2. Press the Run button (▶) at the bottom of the editor.
3. Wait for "Done." in the debug console, then take a screenshot showing both the code and the console.
4. Save it as `Screenshots/05_playground_output.png`.
