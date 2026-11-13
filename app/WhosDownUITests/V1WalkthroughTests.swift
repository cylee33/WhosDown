import Foundation
import XCTest

/// V1 feature walkthrough: one test per feature (1.1–1.28 where a person can see it), driving the real app
/// against the seeded local emulator. Every step is a tap, type, or swipe; every test saves screenshots.
///
/// Opt-in (it changes seeded data): from `firebase/`, `npm run seed`, then
/// `TEST_RUNNER_WHOSDOWN_V1_WALKTHROUGH=1 xcodebuild test -project app/WhosDown.xcodeproj -scheme WhosDown \
///   -destination '<simulator>' -only-testing:WhosDownUITests/V1WalkthroughTests`
/// Re-seed before each full run. Tests run in alphabetical order; later ones expect earlier ones' changes.
@MainActor
final class V1WalkthroughTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["WHOSDOWN_V1_WALKTHROUGH"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_WHOSDOWN_V1_WALKTHROUGH=1 (and re-seed) to run the V1 walkthrough.")
        }
    }

    // MARK: - Helpers

    private func launch(_ account: String? = "1", tab: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        var environment = ["WHOSDOWN_UI_TEST": "1"]
        if let account { environment["WHOSDOWN_DEV_SIGNIN"] = account }
        if let tab { environment["WHOSDOWN_DEV_TAB"] = tab }
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func signedIn(_ account: String, tab: String? = nil) -> XCUIApplication {
        let app = launch(account, tab: tab)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 40), "Sign-in as \(account) never reached the tab bar")
        return app
    }

    private func button(_ text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func text(_ text: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<14 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Not found on screen: \(element)", file: file, line: line)
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 15, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing: \(element)", file: file, line: line)
        reveal(element, in: app, file: file, line: line)
        element.tap()
    }

    /// The button in a sheet: the hittable one with exactly this label. The page underneath has a button
    /// with the same label, and its order in the element tree isn't reliable.
    private func sheetButton(_ label: String, in app: XCUIApplication) -> XCUIElement {
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", label))
        _ = matches.firstMatch.waitForExistence(timeout: 10)
        for _ in 0..<10 {
            if let hittable = matches.allElementsBoundByIndex.first(where: { $0.isHittable }) { return hittable }
            usleep(500_000)
        }
        return matches.firstMatch
    }

    private func type(_ value: String, into field: XCUIElement, in app: XCUIApplication) {
        tap(field, in: app)
        field.typeText(value)
    }

    private func snapshot(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Opens a Match from the Discover list by its title.
    private func openFromList(_ title: String, in app: XCUIApplication) {
        tap(app.tabBars.buttons["Discover"], in: app)
        tap(app.segmentedControls.buttons["List"], in: app)
        tap(button(title, in: app), in: app, timeout: 20)
        XCTAssertTrue(app.navigationBars["Match details"].waitForExistence(timeout: 15))
    }

    /// Opens a Match from My Matches (Upcoming or Hosting).
    private func openFromMyMatches(_ title: String, segment: String, in app: XCUIApplication) {
        tap(app.tabBars.buttons["Matches"], in: app)
        tap(app.segmentedControls.buttons[segment], in: app)
        tap(button(title, in: app), in: app, timeout: 20)
    }

    private func allowSystemAlertIfShown() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "Allow While Using App"] {
            let allow = springboard.buttons[label]
            if allow.waitForExistence(timeout: 3) { allow.tap() }
        }
    }

    // MARK: - Phase 1: identity

    func test01_AccountSignInAndErrors() {
        let app = launch(nil)
        tap(app.buttons["Sign in"], in: app, timeout: 30)
        XCTAssertTrue(app.staticTexts["Welcome back"].waitForExistence(timeout: 10), "1.2 Sign in screen is blank")
        type("alex@whosdown.test", into: app.textFields.firstMatch, in: app)
        type("wrong-password", into: app.secureTextFields.firstMatch, in: app)
        tap(app.buttons.matching(NSPredicate(format: "label == 'Sign in'")).element(boundBy: 0), in: app)
        XCTAssertTrue(text("Wrong email or password", in: app).waitForExistence(timeout: 15), "1.2 wrong password message")
        snapshot("1.2 Wrong password", app)
        let password = app.secureTextFields.firstMatch
        password.tap()
        password.press(forDuration: 1.2)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        password.typeText(XCUIKeyboardKey.delete.rawValue)
        password.typeText("whosdown123")
        tap(app.buttons.matching(NSPredicate(format: "label == 'Sign in'")).element(boundBy: 0), in: app)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "1.2 sign in didn't reach the app")
        snapshot("1.2 Signed in", app)
    }

    func test02_CreateAccountThenOnboarding() {
        let app = launch(nil)
        tap(app.buttons["Create account"], in: app, timeout: 30)
        XCTAssertTrue(text("Takes about 30 seconds", in: app).waitForExistence(timeout: 10), "1.2 Create account screen is blank")
        let fields = app.textFields
        type("Quinn Tester\n", into: fields.element(boundBy: 1), in: app)
        type("qa-\(UUID().uuidString.prefix(6).lowercased())@whosdown.test\n", into: fields.element(boundBy: 0), in: app)
        type("whosdown123\n", into: app.secureTextFields.firstMatch, in: app)
        tap(app.buttons["Continue"], in: app)
        // 1.4 Onboarding: H03 → H42 → H04 → H05 → H44.
        XCTAssertTrue(app.navigationBars["Select your sports"].waitForExistence(timeout: 30), "1.4 onboarding didn't start")
        XCTAssertFalse(app.buttons["Next"].isEnabled, "1.4 rule 1: Next must wait for a sport")
        tap(button("Soccer", in: app), in: app)
        tap(button("Tennis", in: app), in: app)
        snapshot("1.4 H03 sports", app)
        tap(app.buttons["Next"], in: app)
        XCTAssertTrue(app.navigationBars["Set skill levels"].waitForExistence(timeout: 10))
        tap(app.buttons["Intermediate"].firstMatch, in: app)
        tap(app.buttons["Continue"], in: app)
        XCTAssertTrue(app.navigationBars["Complete profile"].waitForExistence(timeout: 15))
        tap(app.buttons["Competitive"], in: app)
        type("Oakland / CMU", into: app.textFields["e.g. Oakland / CMU"], in: app)
        tap(app.buttons["Finish setup"], in: app)
        XCTAssertTrue(app.navigationBars["Stay in the loop"].waitForExistence(timeout: 15))
        tap(app.buttons["Not now"], in: app)
        tap(app.buttons["Continue"], in: app)
        allowSystemAlertIfShown()
        XCTAssertTrue(app.staticTexts["You're all set!"].waitForExistence(timeout: 20), "1.4 didn't reach H44")
        snapshot("1.4 H44 done", app)
        tap(app.buttons["Find Matches"], in: app)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20))
        // 1.22: the new profile shows what onboarding saved.
        tap(app.tabBars.buttons["Profile"], in: app)
        XCTAssertTrue(text("Quinn Tester", in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(text("New player", in: app).waitForExistence(timeout: 15), "1.22 Reliability for a new Player")
        snapshot("1.22 New Player profile", app)
    }

    func test03_GuestBrowsingAndGate() {
        let app = launch("guest", tab: "profile")
        XCTAssertTrue(app.staticTexts["You're browsing as a guest"].waitForExistence(timeout: 40), "1.3 Guest profile")
        tap(app.tabBars.buttons["Matches"], in: app)
        XCTAssertTrue(text("Your Matches live here", in: app).waitForExistence(timeout: 10), "1.3 Guest Matches tab")
        openFromList("Beginner Kickabout", in: app)
        snapshot("1.3 Guest reads Match details", app)
        tap(button("Join", in: app), in: app)
        XCTAssertTrue(app.staticTexts["Sign in to join"].waitForExistence(timeout: 10), "1.3 Join must open the Guest gate")
        snapshot("1.3 Guest gate", app)
        tap(app.buttons["Keep browsing"], in: app)
    }

    func test04_ProfileEdit() {
        let app = signedIn("1", tab: "profile")
        XCTAssertTrue(text("Attendance reliability", in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(text("100%", in: app).waitForExistence(timeout: 15), "1.22 Alex attended 1 of 1 checked-in Matches")
        tap(app.buttons["Edit"], in: app)
        let name = app.textFields.matching(NSPredicate(format: "value == 'Alex Morgan'")).firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText(" QA\n")
        tap(app.buttons["Save profile"], in: app)
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 15), "1.22 save didn't return to the profile")
        XCTAssertTrue(text("Alex Morgan QA", in: app).waitForExistence(timeout: 15), "1.22 edited name shows at once")
        snapshot("1.22 Profile after edit", app)
    }

    // MARK: - Phases 2–3: hosting and discover

    func test05_CreateMatchAtSearchedVenue() {
        let app = signedIn("1", tab: "create")
        tap(button("Choose a sport", in: app), in: app)
        tap(app.buttons["Volleyball"], in: app)
        type("QA Volleyball\n", into: app.textFields["Pickup Volleyball"], in: app)
        tap(button("Choose location", in: app), in: app)
        XCTAssertTrue(app.navigationBars["Choose location"].waitForExistence(timeout: 15))
        type("Wiegand\n", into: app.textFields["Search field, park, or address"], in: app)
        tap(button("CMU Wiegand Gym", in: app), in: app, timeout: 20)
        snapshot("1.12 H40 searched Venue", app)
        tap(app.buttons["Use CMU Wiegand Gym"], in: app)
        tap(app.buttons["Next: venue & details"], in: app)
        XCTAssertTrue(app.navigationBars["Venue & details"].waitForExistence(timeout: 10))
        XCTAssertTrue(text("Indoor", in: app).waitForExistence(timeout: 10), "1.9 indoor Venue says Indoor")
        tap(app.buttons["Review Match"], in: app)
        snapshot("1.11 H19 review", app)
        tap(app.buttons["Publish Match"], in: app)
        XCTAssertTrue(app.staticTexts["Match created!"].waitForExistence(timeout: 20), "1.11 publish")
        XCTAssertTrue(text("1 / 10 joined", in: app).exists, "1.11 the Host counts as the first Player")
        snapshot("1.11 H45 created", app)
        tap(app.buttons["Back to Discover"], in: app)
        tap(app.segmentedControls.buttons["List"], in: app)
        XCTAssertTrue(button("QA Volleyball", in: app).waitForExistence(timeout: 20), "1.11 rule 11: new Match shows in Discover")
    }

    func test06_DiscoverMapListFiltersDetailsWeatherRoster() {
        let app = signedIn("1", tab: "discover")
        // 1.5 map
        XCTAssertTrue(text("NEXT UP", in: app).waitForExistence(timeout: 20), "1.5 Next up card")
        let pin = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Matches at'")).firstMatch
        XCTAssertTrue(pin.waitForExistence(timeout: 20), "1.5 sport pins")
        snapshot("1.5 Map", app)
        // 1.6 list
        tap(app.segmentedControls.buttons["List"], in: app)
        XCTAssertTrue(button("Pickup Soccer", in: app).waitForExistence(timeout: 15), "1.6 list rows")
        XCTAssertTrue(button("Full", in: app).exists || text("Full", in: app).exists, "1.6 Full Match shows Full")
        snapshot("1.6 List", app)
        // 1.7 filters
        tap(app.buttons["Filters"], in: app)
        tap(app.buttons["Basketball"].firstMatch, in: app)
        let show = button("Show", in: app)
        XCTAssertTrue(show.waitForExistence(timeout: 10))
        snapshot("1.7 Filters sheet", app)
        show.tap()
        XCTAssertTrue(button("Basketball Run", in: app).waitForExistence(timeout: 15))
        XCTAssertFalse(button("Pickup Soccer", in: app).exists, "1.7 filter by sport")
        snapshot("1.7 Filtered list", app)
        tap(app.buttons["Filters"], in: app)
        tap(app.buttons["Reset"], in: app)
        tap(button("Show", in: app), in: app)
        // 1.8 details + 1.9 weather + 1.10 roster
        tap(button("Basketball Run", in: app), in: app, timeout: 15)
        XCTAssertTrue(app.navigationBars["Match details"].waitForExistence(timeout: 15))
        XCTAssertTrue(text("joined", in: app).waitForExistence(timeout: 10), "1.8 spots line")
        let weather = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '°F' OR label CONTAINS 'Indoor'")).firstMatch
        XCTAssertTrue(weather.waitForExistence(timeout: 20), "1.9 weather line on an outdoor Match (needs internet)")
        snapshot("1.8 Match details (indoor)", app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tap(button("Ultimate Frisbee", in: app), in: app, timeout: 15)
        let outdoor = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '°F'")).firstMatch
        XCTAssertTrue(outdoor.waitForExistence(timeout: 20), "1.9 forecast on an outdoor Match (needs internet)")
        snapshot("1.9 Weather on an outdoor Match", app)
        tap(button("PLAYERS", in: app), in: app)
        XCTAssertTrue(app.navigationBars["Who's going"].waitForExistence(timeout: 10))
        XCTAssertTrue(text("Host ·", in: app).waitForExistence(timeout: 15), "1.10 Host first with Reliability")
        snapshot("1.10 Roster", app)
        tap(button("Taylor Ross", in: app), in: app)
        XCTAssertTrue(text("Attendance reliability", in: app).waitForExistence(timeout: 15), "1.22 H10 from the roster")
        snapshot("1.22 H10 Player profile", app)
    }

    // MARK: - Phase 4: joining

    func test07_JoinOpenMatch() {
        let app = signedIn("1")
        openFromList("Beginner Kickabout", in: app)
        tap(app.buttons["Join"], in: app)
        XCTAssertTrue(text("You're in for Beginner Kickabout", in: app).waitForExistence(timeout: 20), "1.13 one-tap join")
        snapshot("1.13 Joined", app)
    }

    func test08_RequestToJoinThenHostApproves() {
        let player = signedIn("taylor@whosdown.test")
        openFromList("Indoor Volleyball", in: player)
        tap(player.buttons["Request to join"], in: player)
        XCTAssertTrue(player.buttons["Send join request"].waitForExistence(timeout: 10), "1.14 Join review sheet")
        snapshot("1.14 Join review", player)
        player.buttons["Send join request"].tap()
        XCTAssertTrue(text("Waiting for host approval", in: player).waitForExistence(timeout: 20), "1.14 Pending")
        snapshot("1.14 Pending", player)
        player.terminate()

        let host = signedIn("mina@whosdown.test")
        openFromMyMatches("Indoor Volleyball", segment: "Hosting", in: host)
        tap(button("Join requests", in: host), in: host)
        tap(host.buttons["Approve"].firstMatch, in: host, timeout: 20)
        snapshot("1.15 Approved", host)
        host.terminate()

        let approved = signedIn("taylor@whosdown.test")
        openFromMyMatches("Indoor Volleyball", segment: "Upcoming", in: approved)
        XCTAssertTrue(text("You're in for Indoor Volleyball", in: approved).waitForExistence(timeout: 20), "1.14 live change to Approved")
        // 1.21: the approval arrived in the inbox.
        tap(approved.tabBars.buttons["Discover"], in: approved)
        tap(button("Notifications", in: approved), in: approved)
        XCTAssertTrue(text("Indoor Volleyball", in: approved).waitForExistence(timeout: 15), "1.21 approved notification")
        snapshot("1.21 Inbox", approved)
    }

    func test09_HostDeclinesWithMessage() {
        let player = signedIn("sam@whosdown.test")
        openFromList("Indoor Volleyball", in: player)
        tap(player.buttons["Request to join"], in: player)
        tap(player.buttons["Send join request"], in: player)
        XCTAssertTrue(text("Waiting for host approval", in: player).waitForExistence(timeout: 20))
        player.terminate()

        let host = signedIn("mina@whosdown.test")
        openFromMyMatches("Indoor Volleyball", segment: "Hosting", in: host)
        tap(button("Join requests", in: host), in: host)
        tap(host.buttons["Decline"].firstMatch, in: host, timeout: 20)
        type("Full lineup tonight, sorry!", into: host.textFields.firstMatch, in: host)
        snapshot("1.15 Decline sheet", host)
        tap(sheetButton("Decline", in: host), in: host)
        host.terminate()

        let declined = signedIn("sam@whosdown.test")
        openFromMyMatches("Indoor Volleyball", segment: "Upcoming", in: declined)
        XCTAssertTrue(text("This request wasn't approved", in: declined).waitForExistence(timeout: 20), "1.14 Declined state")
        XCTAssertTrue(text("Full lineup tonight", in: declined).exists, "1.14 shows the Host's message")
        snapshot("1.14 Declined", declined)
    }

    func test10_LeaveMatch() {
        let app = signedIn("1")
        openFromMyMatches("Beginner Kickabout", segment: "Upcoming", in: app)
        tap(button("Leave Match", in: app), in: app)
        XCTAssertTrue(app.staticTexts["Leave this Match?"].waitForExistence(timeout: 10), "1.16 confirmation sheet")
        snapshot("1.16 Leave sheet", app)
        tap(sheetButton("Leave Match", in: app), in: app)
        XCTAssertTrue(app.buttons["Join"].waitForExistence(timeout: 20), "1.16 after leaving, Join is back")
        snapshot("1.16 After leaving", app)
    }

    // MARK: - Phase 5: follow-through

    func test11_MyMatchesAndChat() {
        let app = signedIn("1", tab: "matches")
        XCTAssertTrue(button("Pickup Soccer", in: app).waitForExistence(timeout: 20), "1.19 Upcoming")
        snapshot("1.19 Upcoming", app)
        tap(app.segmentedControls.buttons["Hosting"], in: app)
        XCTAssertTrue(button("Pickleball Doubles", in: app).waitForExistence(timeout: 15), "1.19 Hosting")
        tap(app.segmentedControls.buttons["Past"], in: app)
        XCTAssertTrue(button("Sunday 7v7", in: app).waitForExistence(timeout: 15), "1.19 Past")
        snapshot("1.19 Past", app)
        openFromMyMatches("Pickup Soccer", segment: "Upcoming", in: app)
        tap(button("Open Match chat", in: app), in: app)
        XCTAssertTrue(text("Can someone bring an extra ball?", in: app).waitForExistence(timeout: 15), "1.20 seeded messages")
        type("QA chat check", into: app.textFields["Message Players…"], in: app)
        tap(app.buttons["Send"], in: app)
        XCTAssertTrue(text("QA chat check", in: app).waitForExistence(timeout: 15), "1.20 send")
        snapshot("1.20 Match chat", app)
    }

    // MARK: - Phase 6: lifecycle

    func test12_WaitlistMovesUpOnOpenMatch() {
        let alex = signedIn("1")
        openFromMyMatches("7v7 at Schenley", segment: "Upcoming", in: alex)
        tap(button("Leave Match", in: alex), in: alex)
        tap(sheetButton("Leave Match", in: alex), in: alex)
        // Taylor was first in line, so the freed spot went to Taylor: the Match is Full again.
        XCTAssertTrue(button("Join waitlist", in: alex).waitForExistence(timeout: 20), "1.17 Full again after the line moved up")
        tap(button("Join waitlist", in: alex), in: alex)
        XCTAssertTrue(text("WAITLIST", in: alex).waitForExistence(timeout: 20), "1.17 joined the waitlist")
        snapshot("1.17 Waitlisted", alex)
        alex.terminate()

        let taylor = signedIn("taylor@whosdown.test")
        openFromMyMatches("7v7 at Schenley", segment: "Upcoming", in: taylor)
        XCTAssertTrue(text("You're in for 7v7 at Schenley", in: taylor).waitForExistence(timeout: 20), "1.17 first in line got the spot")
        snapshot("1.17 Promoted", taylor)
    }

    func test13_EditThenCancelMatch() {
        let app = signedIn("1")
        openFromMyMatches("Sunday Tennis", segment: "Hosting", in: app)
        tap(button("Edit Match", in: app), in: app)
        let note = app.textFields["Note to Players"]
        type("Bring two cans of balls.", into: note, in: app)
        snapshot("1.18 Edit Match", app)
        tap(app.buttons["Save changes"], in: app)
        tap(button("Cancel Match", in: app), in: app, timeout: 20)
        XCTAssertTrue(app.staticTexts["Cancel this Match?"].waitForExistence(timeout: 10))
        type("Courts closed for resurfacing", into: app.textFields.firstMatch, in: app)
        snapshot("1.18 Cancel sheet", app)
        tap(sheetButton("Cancel Match", in: app), in: app)
        tap(app.tabBars.buttons["Discover"], in: app)
        tap(app.segmentedControls.buttons["List"], in: app)
        XCTAssertFalse(button("Sunday Tennis", in: app).waitForExistence(timeout: 5), "1.18 cancelled Match leaves Discover")
    }

    func test14_CheckIn() {
        let app = signedIn("1", tab: "matches")
        tap(app.segmentedControls.buttons["Past"], in: app)
        XCTAssertTrue(button("Recent Hoops", in: app).waitForExistence(timeout: 20), "1.19 ended Match is in Past")
        tap(app.buttons["Check in"].firstMatch, in: app)
        XCTAssertTrue(app.navigationBars["Check in"].waitForExistence(timeout: 15), "1.27 Check-in screen")
        let mina = app.switches["Mina Kim attended"]
        tap(mina, in: app)
        snapshot("1.27 Check-in", app)
        tap(app.buttons["Submit check-in"], in: app)
        XCTAssertTrue(app.buttons["Update check-in"].waitForExistence(timeout: 20), "1.27 saved")
    }

    func test15_TransferHost() {
        let app = signedIn("1")
        openFromMyMatches("Pickleball Doubles", segment: "Hosting", in: app)
        tap(button("Transfer host", in: app), in: app)
        let sam = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sam Lee'"))
        XCTAssertTrue(sam.firstMatch.waitForExistence(timeout: 10))
        sam.element(boundBy: sam.count - 1).tap()
        snapshot("1.28 Transfer sheet", app)
        let transfer = sheetButton("Transfer host", in: app)
        XCTAssertTrue(transfer.isEnabled, "1.28 picking a Player enables Transfer host")
        transfer.tap()
        app.terminate()

        let newHost = signedIn("sam@whosdown.test")
        openFromMyMatches("Pickleball Doubles", segment: "Hosting", in: newHost)
        XCTAssertTrue(button("Join requests", in: newHost).waitForExistence(timeout: 20), "1.28 new Host sees Manage Match")
        snapshot("1.28 New Host dashboard", newHost)
    }
}
