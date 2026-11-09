import Foundation
import XCTest

/// Runs against seeded demo-whosdown. Exercises actual SwiftUI navigation and system EventKit UI.
@MainActor
final class Phase7UITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard let url = URL(string: "http://127.0.0.1:9099"), (try? Data(contentsOf: url)) != nil else {
            throw XCTSkip("Start and seed the local Firebase emulators before running UI acceptance tests.")
        }
    }

    private func launch(match: String = "m_soccer_tonight", account: String = "1", largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["WHOSDOWN_UI_TEST"] = "1"
        app.launchEnvironment["WHOSDOWN_DEV_SIGNIN"] = account
        app.launchEnvironment["WHOSDOWN_DEV_MATCH_ID"] = match
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["Match actions"].waitForExistence(timeout: 30))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Could not reach \(element)")
    }

    func testApprovedPlayerOpensAndCancelsSystemCalendarEditor() {
        let app = launch()
        let calendar = app.buttons["Calendar"]
        XCTAssertTrue(calendar.waitForExistence(timeout: 15))
        reveal(calendar, in: app)
        calendar.tap()
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.textFields.containing(NSPredicate(format: "value CONTAINS %@", "Pickup Soccer")).firstMatch.exists, app.debugDescription)
        cancel.tap()
        // Some iOS versions ask whether to discard a newly edited event.
        if app.buttons["Discard Changes"].waitForExistence(timeout: 2) { app.buttons["Discard Changes"].tap() }
        XCTAssertTrue(calendar.waitForExistence(timeout: 10))
    }

    func testMatchReportValidatesAndSubmitsAtLargestTextSize() throws {
        let app = launch(largeText: true)
        app.buttons["Match actions"].tap()
        app.buttons["Report Match"].tap()
        let submit = app.buttons["Submit report"]
        XCTAssertTrue(submit.waitForExistence(timeout: 10))
        XCTAssertFalse(submit.isEnabled)
        let reason = app.buttons["Harassment or unsafe behavior"]
        reveal(reason, in: app)
        reason.tap()
        reveal(submit, in: app)
        XCTAssertTrue(submit.isEnabled)
        try app.performAccessibilityAudit(for: [.elementDetection, .sufficientElementDescription, .textClipped])
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "H33 report — Accessibility XXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        submit.tap()
        XCTAssertTrue(app.alerts["Thanks. We'll review your report."].waitForExistence(timeout: 15))
        app.alerts.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Match actions"].waitForExistence(timeout: 10))
    }

    func testGuestCannotAddCalendarAndReportingOpensAccountGate() {
        let app = launch(account: "guest")
        app.buttons["Match actions"].tap()
        XCTAssertFalse(app.buttons["Add to calendar"].exists)
        app.buttons["Report Match"].tap()
        XCTAssertTrue(app.buttons["Create account"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Submit report"].exists)
    }

    func testHostCalendarAndCancelSheetAtLargestTextSize() {
        let app = launch(account: "jamie@whosdown.test", largeText: true)
        app.buttons["Match actions"].tap()
        XCTAssertTrue(app.buttons["Add to calendar"].exists)
        app.tap() // dismiss menu
        let manage = app.buttons["Manage Match"]
        reveal(manage, in: app)
        manage.tap()
        let cancel = app.buttons["Cancel Match"]
        reveal(cancel, in: app)
        cancel.tap()
        XCTAssertTrue(app.staticTexts["Cancel this Match?"].waitForExistence(timeout: 10))
        let keep = app.buttons["Keep Match"]
        reveal(keep, in: app)
        keep.tap()
        XCTAssertTrue(app.navigationBars["Manage Match"].exists)
    }
    func testCalendarEditorSavesAnEvent() {
        let app = launch()
        let calendar = app.buttons["Calendar"]
        XCTAssertTrue(calendar.waitForExistence(timeout: 15))
        reveal(calendar, in: app)
        calendar.tap()
        let add = app.navigationBars["New Event"].buttons.matching(NSPredicate(format: "label IN %@", ["Add", "Done", "Save"])).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(add.isEnabled, "Simulator needs a writable local calendar")
        add.tap()
        XCTAssertTrue(calendar.waitForExistence(timeout: 15))
        XCTAssertFalse(app.navigationBars["New Event"].exists)
    }

    func testPendingAndWaitlistedPlayersCannotAddCalendar() {
        let app = launch(account: "taylor@whosdown.test")
        app.buttons["Match actions"].tap()
        XCTAssertFalse(app.buttons["Add to calendar"].exists)
        app.terminate()
        let waitlisted = launch(match: "m_7v7_full", account: "taylor@whosdown.test")
        waitlisted.buttons["Match actions"].tap()
        XCTAssertFalse(waitlisted.buttons["Add to calendar"].exists)
    }

    func testPlayerReportRetainsMatchContext() {
        let app = launch(account: "taylor@whosdown.test")
        let host = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Jamie Morales · Host")).firstMatch
        reveal(host, in: app)
        host.tap()
        let safety = app.buttons["Safety & reporting"]
        XCTAssertTrue(safety.waitForExistence(timeout: 15))
        reveal(safety, in: app)
        safety.tap()
        XCTAssertTrue(app.staticTexts["Report Jamie Morales"].waitForExistence(timeout: 10))
        app.buttons["Other"].tap()
        let submit = app.buttons["Submit report"]
        reveal(submit, in: app)
        submit.tap()
        XCTAssertTrue(app.alerts["Thanks. We'll review your report."].waitForExistence(timeout: 15))
        app.alerts.buttons["Done"].tap()
        XCTAssertTrue(safety.waitForExistence(timeout: 10))
    }

    func testCancelledMatchShowsCancellationRatherThanJoinedScreen() {
        let app = launch(match: "m_cancelled", account: "sam@whosdown.test")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Cancelled:")).firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Calendar"].exists)
        XCTAssertFalse(app.buttons["Leave Match"].exists)
    }

    func testReminderTapRoutesToTheCorrectMatch() {
        let app = XCUIApplication()
        app.launchEnvironment["WHOSDOWN_UI_TEST"] = "1"
        app.launchEnvironment["WHOSDOWN_DEV_SIGNIN"] = "1"
        app.launchEnvironment["WHOSDOWN_DEV_NOTIFICATION_MATCH_ID"] = "m_pickle"
        app.launch()
        XCTAssertTrue(app.staticTexts["Pickleball Doubles"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Done"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

}
