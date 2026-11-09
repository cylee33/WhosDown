import Foundation
import Testing
import UserNotifications
@testable import WhosDown

@MainActor
private final class TestNotificationCenter: ReminderNotificationCenter {
    var status: UNAuthorizationStatus = .authorized
    var requests: [String: UNNotificationRequest] = [:]
    var additions = 0
    var failNext = false
    func authorizationStatus() async -> UNAuthorizationStatus { status }
    func pendingRequests() async -> [UNNotificationRequest] { Array(requests.values) }
    func add(_ request: UNNotificationRequest) async throws {
        if failNext { failNext = false; throw URLError(.notConnectedToInternet) }
        requests[request.identifier] = request
        additions += 1
    }
    func removePending(identifiers: [String]) { for id in identifiers { requests[id] = nil } }
}

@MainActor
struct ReminderSchedulerTests {
    private func reminder(hours: Double = 2) -> MatchReminder {
        MatchReminder(matchId: "scheduler-test", title: "Pickup Soccer starts in 1 hour", venue: "CMU Soccer Field",
                      fireDate: Date(timeIntervalSince1970: 1_900_000_000).addingTimeInterval(hours * 3600))
    }

    @Test func addsReplacesAndRemovesActualNotificationRequests() async throws {
        let center = TestNotificationCenter()
        let scheduler = ReminderScheduler(notifications: center)
        let first = reminder()
        await scheduler.sync([first])
        let request = try #require(center.requests[first.identifier])
        #expect(request.content.title == first.title)
        #expect(request.content.body == first.venue)
        #expect(request.content.userInfo["matchId"] as? String == first.matchId)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.nextTriggerDate() == first.fireDate)
        await scheduler.sync([first])
        #expect(center.additions == 1)
        let moved = reminder(hours: 3)
        await scheduler.sync([moved])
        #expect(center.additions == 2)
        #expect((center.requests[first.identifier]?.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() == moved.fireDate)
        let unrelated = UNNotificationRequest(identifier: "unrelated", content: UNMutableNotificationContent(), trigger: nil)
        center.requests[unrelated.identifier] = unrelated
        await scheduler.sync([])
        #expect(center.requests.keys.sorted() == ["unrelated"])
    }

    @Test func deniedAndUndeterminedPermissionsNeverScheduleOrPrompt() async {
        let center = TestNotificationCenter()
        let scheduler = ReminderScheduler(notifications: center)
        await scheduler.sync([reminder()])
        center.status = .denied
        await scheduler.sync([reminder()])
        #expect(scheduler.denied)
        #expect(center.requests.isEmpty)
        center.status = .notDetermined
        await scheduler.sync([reminder()])
        #expect(!scheduler.denied)
        #expect(center.requests.isEmpty)
        // The service boundary exposes no request-authorization operation: H05 owns that prompt.
    }

    @Test func scheduleFailureIsVisibleAndNextSyncRetries() async {
        let center = TestNotificationCenter()
        let scheduler = ReminderScheduler(notifications: center)
        center.failNext = true
        await scheduler.sync([reminder()])
        #expect(scheduler.errorMessage != nil)
        await scheduler.sync([reminder()])
        #expect(scheduler.errorMessage == nil)
        #expect(center.requests.count == 1)
    }

    @Test func notificationTapRoutesOnlyAValidMatchIdentifier() {
        let scheduler = ReminderScheduler(notifications: TestNotificationCenter())
        scheduler.openMatch(from: [:])
        scheduler.openMatch(from: ["matchId": 123])
        scheduler.openMatch(from: ["matchId": ""])
        #expect(scheduler.openedMatchId == nil)
        scheduler.openMatch(from: ["matchId": "m1"])
        #expect(scheduler.openedMatchId == "m1")
    }

    @Test func osNotificationServiceStoresAndReplacesReminder() async throws {
        let center = UNUserNotificationCenter.current()
        // Provisional authorization is silent and affects only the simulator test host.
        let allowed = try await center.requestAuthorization(options: [.alert, .sound, .provisional])
        try #require(allowed, "Allow notifications for the simulator test host to exercise OS scheduling")
        let scheduler = ReminderScheduler(center: center)
        let item = MatchReminder(matchId: "os-test", title: "Scheduler integration test", venue: "CMU", fireDate: .now.addingTimeInterval(7200))
        await scheduler.sync([item])
        let pending = await center.pendingNotificationRequests()
        #expect(pending.contains { $0.identifier == item.identifier && $0.content.userInfo["matchId"] as? String == "os-test" })
        await scheduler.sync([])
        #expect(!(await center.pendingNotificationRequests()).contains { $0.identifier == item.identifier })
    }
}
