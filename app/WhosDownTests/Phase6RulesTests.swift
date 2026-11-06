import Foundation
import Testing
@testable import WhosDown

struct WaitlistRulesTests {
    @Test func openMatchPromotesTheFirstInLine() {
        #expect(WaitlistRules.promotedIds(joinType: .open, waitlistIds: ["a", "b"], spotsOpened: 1, hasStarted: false) == ["a"])
        #expect(WaitlistRules.promotedIds(joinType: .open, waitlistIds: ["a", "b", "c"], spotsOpened: 2, hasStarted: false) == ["a", "b"])
    }

    @Test func approvalRequiredAndStartedPromoteNobody() {
        #expect(WaitlistRules.promotedIds(joinType: .approvalRequired, waitlistIds: ["a"], spotsOpened: 1, hasStarted: false).isEmpty)
        #expect(WaitlistRules.promotedIds(joinType: .open, waitlistIds: ["a"], spotsOpened: 1, hasStarted: true).isEmpty)
        #expect(WaitlistRules.promotedIds(joinType: .open, waitlistIds: ["a"], spotsOpened: 0, hasStarted: false).isEmpty)
        #expect(WaitlistRules.cap == 50)
    }
}

struct CheckInRulesTests {
    @Test func windowRunsFromStartUntilFortyEightHoursAfterTheEnd() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        var match = Match.sample(startsInHours: 0)
        match.startTime = start
        match.endTime = start.addingTimeInterval(3600)
        #expect(!CheckInRules.isOpen(match, now: start.addingTimeInterval(-1)))
        #expect(CheckInRules.isOpen(match, now: start))
        #expect(CheckInRules.isOpen(match, now: match.endTime.addingTimeInterval(48 * 3600)))
        #expect(!CheckInRules.isOpen(match, now: match.endTime.addingTimeInterval(48 * 3600 + 1)))
        match.status = .cancelled
        #expect(!CheckInRules.isOpen(match, now: start.addingTimeInterval(10)))
    }
}

struct MatchChangeTests {
    @Test func timeAndLimitAreListedAndDescriptionIsSeparate() {
        var match = Match.sample()
        match.notes = "Bring a ball"
        let edits = MatchEdits(
            startTime: match.startTime.addingTimeInterval(1800), endTime: match.endTime, playerLimit: match.playerLimit + 2,
            joinType: match.joinType, notes: "Bring a ball", venue: nil, notify: true, hostNote: nil
        )
        let fields = MatchChange.changes(from: match, edits: edits).map(\.field)
        #expect(fields.contains("Time"))
        #expect(fields.contains("Player limit"))
        #expect(!fields.contains("Description"))
    }
}
