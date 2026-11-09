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
        // Leave the simulator on the unlocked Home Screen. Opening Notification Center
        // can put this simulator into its Lock Screen UI, where a tap only expands the row.
        let delivered = springboard.staticTexts["WhosDown delivery \(run.prefix(6)) starts in 1 hour"]
        XCTAssertTrue(delivered.waitForExistence(timeout: 20), springboard.debugDescription)
        let screenshot = XCTAttachment(screenshot: springboard.screenshot())
        screenshot.name = "Actual OS-delivered local reminder with app terminated"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        delivered.tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), springboard.debugDescription)
        XCTAssertTrue(app.staticTexts["Pickleball Doubles"].waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(app.buttons["Done"].exists)
    }
}
