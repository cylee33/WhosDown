import Foundation
import XCTest

/// Every V1 screen is rendered using the real views with deterministic in-memory data.
@MainActor
final class ScreenAuditTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
        guard ProcessInfo.processInfo.environment["WHOSDOWN_FULL_AUDIT"] == "1" else {
            throw XCTSkip("Set WHOSDOWN_FULL_AUDIT in the xctestrun EnvironmentVariables for the exhaustive screen audit.")
        }
    }
    func testEveryScreenAtDefaultTextSize() throws { try audit(large: false) }
    func testEveryScreenAtLargestTextSize() throws { try audit(large: true) }

    private func audit(large: Bool) throws {
        let app = XCUIApplication()
        let start = Int(ProcessInfo.processInfo.environment["WHOSDOWN_AUDIT_START"] ?? "") ?? 0
        let end = Int(ProcessInfo.processInfo.environment["WHOSDOWN_AUDIT_END"] ?? "") ?? 45
        app.launchEnvironment = ["WHOSDOWN_UI_TEST": "1", "WHOSDOWN_DEV_SIGNIN": "1", "WHOSDOWN_SCREEN_AUDIT": "1", "WHOSDOWN_AUDIT_START": String(start)]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", large ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        var failures: [String] = []
        for index in start..<end {
            let title = app.staticTexts["audit-screen-title"]
            XCTAssertTrue(title.waitForExistence(timeout: 30))
            XCTAssertTrue(title.label.hasPrefix("\(index + 1)/45"), title.label)
            // Wait for fixture listeners and UIKit presentation to settle before auditing.
            let name = title.label
            do { try auditProduct(app) } catch { failures.append(name) }
            capture(app, name: "\(large ? "AXXXL" : "Default") \(name) top")
            if ![9, 10].contains(index) { // Map swipes pan the map rather than scroll the screen.
                app.swipeUp(velocity: .fast)
                app.swipeUp(velocity: .fast)
                do { try auditProduct(app) } catch { failures.append(name + " bottom") }
                capture(app, name: "\(large ? "AXXXL" : "Default") \(name) bottom")
            }
            app.buttons["audit-next"].tap()
        }
        if end == 45 { XCTAssertTrue(app.staticTexts["audit-complete"].waitForExistence(timeout: 15)) }
        XCTAssertTrue(failures.isEmpty, "Accessibility issues: \(failures.joined(separator: ", "))")
    }
    private func auditProduct(_ app: XCUIApplication) throws {
        // A sheet's accessibility tree arrives before its detent animation finishes.
        // Auditing that intermediate geometry reports clipping that is absent once settled.
        let settled = expectation(description: "Presentation and scrolling settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .textClipped]) { issue in
            // These two controls belong to the test harness and are excluded from the product audit.
            issue.element?.identifier.hasPrefix("audit-") == true
        }
    }
    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
