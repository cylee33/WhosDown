import Foundation
import Testing
@testable import WhosDown

struct ReminderPlannerTests {
    let now = Date(timeIntervalSince1970: 1_000_000)
    func match(_ id: String = "m1", hours: Double = 2, host: String = "host") -> Match {
        var match = Match.sample()
        match.id = id
        match.hostId = host
        match.startTime = now.addingTimeInterval(hours * 3600)
        return match
    }
    @Test func approvedAndHostedOnlyAndDeduplicated() {
        let approved = match()
        let hosted = match("m2", host: "me")
        let plan = ReminderPlanner.plan(matches: [approved, hosted, approved, match("pending")], approvedIds: ["m1"], userId: "me", now: now)
        #expect(plan.count == 2)
        #expect(plan.first?.identifier == "match-m1")
        #expect(plan.first?.fireDate == now.addingTimeInterval(3600))
        #expect(plan.first?.title == "\(approved.title) starts in 1 hour")
        #expect(plan.first?.venue == approved.venueName)
    }
    @Test func skipsCancelledStartedAndWithinHour() {
        var cancelled = match("cancelled")
        cancelled.status = .cancelled
        let values = [cancelled, match("started", hours: -1), match("soon", hours: 0.5), match("boundary", hours: 1)]
        #expect(ReminderPlanner.plan(matches: values, approvedIds: Set(values.compactMap(\.id)), userId: "me", now: now).isEmpty)
    }
    @Test func editsMoveReminderAndLeavingRemovesIt() {
        let original = ReminderPlanner.plan(matches: [match()], approvedIds: ["m1"], userId: "me", now: now)
        let edited = ReminderPlanner.plan(matches: [match(hours: 3)], approvedIds: ["m1"], userId: "me", now: now)
        #expect(original.first?.identifier == edited.first?.identifier)
        #expect(edited.first?.fireDate == now.addingTimeInterval(7200))
        #expect(ReminderPlanner.plan(matches: [match()], approvedIds: [], userId: "me", now: now).isEmpty)
    }
    @Test func keepsSoonestSixtyFour() {
        let values = (0..<70).map { match("m\($0)", hours: Double($0 + 2), host: "me") }
        let plan = ReminderPlanner.plan(matches: values.reversed(), approvedIds: [], userId: "me", now: now)
        #expect(plan.count == 64)
        #expect(plan.first?.matchId == "m0")
        #expect(plan.last?.matchId == "m63")
    }
}
