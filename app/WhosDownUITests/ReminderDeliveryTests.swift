import Foundation
import XCTest

@MainActor
final class ReminderDeliveryTests: XCTestCase {
    func testDeliveredReminderColdLaunchesTheCorrectMatch() throws {
        continueAfterFailure = false
        guard let url = URL(string: "http://127.0.0.1:9099"), (try? Data(contentsOf: url)) != nil else {
            throw XCTSkip("Start the seeded demo emulator to verify real local notification delivery.")
        }
        let app = XCUIApplication()
        let run = UUID().uuidString
        app.launchEnvironment = ["WHOSDOWN_UI_TEST": "1", "WHOSDOWN_DEV_SIGNIN": "1", "WHOSDOWN_DELIVERY_PROBE": run]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout: 8) { springboard.alerts.buttons["Allow"].tap() }
        XCTAssertTrue(app.staticTexts["delivery-probe-ready"].waitForExistence(timeout: 40))
        XCUIDevice.shared.press(.home)
        app.terminate()
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        let delivered = springboard.staticTexts["WhosDown delivery \(run.prefix(6)) starts in 1 hour"]
        if !delivered.waitForExistence(timeout: 20) {
            springboard.swipeUp()
        }
        XCTAssertTrue(delivered.waitForExistence(timeout: 20), springboard.debugDescription)
        let screenshot = XCTAttachment(screenshot: springboard.screenshot())
        screenshot.name = "Actual OS-delivered local reminder with app terminated"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        delivered.tap()
        // Notification Center can first expand a grouped notification before opening it.
        if !app.wait(for: .runningForeground, timeout: 3), delivered.exists {
            delivered.tap()
        }
        if !app.wait(for: .runningForeground, timeout: 5) {
            let bottom = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            bottom.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
        }
        XCTAssertTrue(app.staticTexts["Pickleball Doubles"].waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(app.buttons["Done"].exists)
    }
}
