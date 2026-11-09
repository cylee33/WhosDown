import Foundation
import XCTest

/// Opt-in paired run: scripts/run_two_simulator_acceptance.py starts each role on a different simulator.
/// All coordination reads are restricted to the local demo emulator; every user action uses the app UI.
@MainActor
final class TwoDeviceAcceptanceTests: XCTestCase {
    private var title: String { ProcessInfo.processInfo.environment["WHOSDOWN_QA_TITLE"]! }

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["WHOSDOWN_TWO_DEVICE"] == "1" else {
            throw XCTSkip("Run the paired two-simulator acceptance script to exercise this scenario.")
        }
    }

    private func launch(account: String, tab: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["WHOSDOWN_UI_TEST": "1", "WHOSDOWN_DEV_SIGNIN": account, "WHOSDOWN_DEV_TAB": tab]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 40))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<16 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func snapshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHostPublishesApprovesAndChats() async throws {
        let app = launch(account: "jamie@whosdown.test", tab: "create")
        XCTAssertTrue(app.navigationBars["Create Match"].waitForExistence(timeout: 15))
        button(containing: "Choose a sport", in: app).tap()
        app.buttons["Soccer"].tap()
        let titleField = app.textFields["Pickup Soccer"]
        titleField.tap()
        titleField.typeText(title + "\n")
        let location = button(containing: "Choose location", in: app)
        reveal(location, in: app)
        location.tap()
        let venue = button(containing: "CMU Soccer Field", in: app)
        XCTAssertTrue(venue.waitForExistence(timeout: 20))
        reveal(venue, in: app)
        venue.tap()
        app.buttons["Use CMU Soccer Field"].tap()
        let approval = app.buttons["Approval required"]
        reveal(approval, in: app)
        approval.tap()
        app.buttons["Next: venue & details"].tap()
        XCTAssertTrue(app.navigationBars["Venue & details"].waitForExistence(timeout: 10))
        app.buttons["Review Match"].tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 10))
        app.buttons["Publish Match"].tap()
        XCTAssertTrue(app.staticTexts["Match created!"].waitForExistence(timeout: 20), app.debugDescription)
        snapshot("Host published Match", app: app)
        app.tabBars.buttons["Matches"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Hosting"].waitForExistence(timeout: 15))
        app.segmentedControls.buttons["Hosting"].tap()
        let hosted = button(containing: title, in: app)
        reveal(hosted, in: app)
        hosted.tap()
        let requests = button(containing: "Join requests", in: app)
        XCTAssertTrue(requests.waitForExistence(timeout: 15))
        requests.tap()
        let approve = app.buttons["Approve"].firstMatch
        XCTAssertTrue(approve.waitForExistence(timeout: 240), "Player on the other simulator did not request to join")
        snapshot("Host received Player request", app: app)
        approve.tap()
        app.navigationBars["Join requests"].buttons.element(boundBy: 0).tap()
        let chat = button(containing: "Match chat", in: app)
        reveal(chat, in: app)
        chat.tap()
        XCTAssertTrue(app.staticTexts["Player two-device hello"].waitForExistence(timeout: 180))
        let message = app.textFields["Message Players…"]
        message.tap()
        message.typeText("Host two-device reply")
        app.buttons["Send"].tap()
        XCTAssertTrue(app.staticTexts["Host two-device reply"].waitForExistence(timeout: 15))
        snapshot("Host received and replied to chat", app: app)
    }

    func testPlayerDiscoversRequestsAndChats() async throws {
        // Wait for the other simulator to publish through the actual Create UI.
        let published = try await waitForPublishedMatch()
        XCTAssertFalse(published.isEmpty)
        let app = launch(account: "taylor@whosdown.test", tab: "discover")
        XCTAssertTrue(app.segmentedControls.buttons["List"].waitForExistence(timeout: 15))
        app.segmentedControls.buttons["List"].tap()
        let match = button(containing: title, in: app)
        reveal(match, in: app)
        match.tap()
        let request = app.buttons["Request to join"]
        reveal(request, in: app)
        request.tap()
        XCTAssertTrue(app.buttons["Send join request"].waitForExistence(timeout: 10))
        app.buttons["Send join request"].tap()
        // The Host's other simulator approves live; no relaunch or injected RSVP state.
        XCTAssertTrue(app.buttons["Open Match chat"].waitForExistence(timeout: 180))
        snapshot("Player received live approval", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Matches"].tap()
        XCTAssertTrue(app.navigationBars["My Matches"].waitForExistence(timeout: 15))
        let mine = button(containing: title, in: app)
        reveal(mine, in: app)
        mine.tap()
        XCTAssertTrue(app.buttons["Open Match chat"].waitForExistence(timeout: 15))
        app.buttons["Open Match chat"].tap()
        let message = app.textFields["Message Players…"]
        XCTAssertTrue(message.waitForExistence(timeout: 15))
        message.tap()
        message.typeText("Player two-device hello")
        app.buttons["Send"].tap()
        XCTAssertTrue(app.staticTexts["Host two-device reply"].waitForExistence(timeout: 180))
        snapshot("Player received Host reply", app: app)
    }

    private func waitForPublishedMatch() async throws -> String {
        let url = URL(string: "http://127.0.0.1:8080/v1/projects/demo-whosdown/databases/(default)/documents:runQuery")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["structuredQuery": [
            "from": [["collectionId": "matches"]],
            "where": ["fieldFilter": ["field": ["fieldPath": "title"], "op": "EQUAL", "value": ["stringValue": title]]],
        ]])
        for _ in 0..<300 {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let document = rows.compactMap({ $0["document"] as? [String: Any] }).first,
               let name = document["name"] as? String { return name }
            try await Task.sleep(for: .seconds(1))
        }
        XCTFail("Host on the other simulator did not publish the Match")
        return ""
    }
}
