import EventKit
import Foundation
import Testing
@testable import WhosDown

@MainActor
struct CalendarEventBuilderTests {
    @Test func fillsEventWithoutRequestingCalendarAccess() {
        var match = Match.sample()
        match.notes = "Bring a ball"
        // EventKit stores dates to whole-second precision.
        match.startTime = Date(timeIntervalSince1970: 1_800_000_000)
        match.endTime = match.startTime.addingTimeInterval(5400)
        let event = CalendarEventBuilder.event(for: match, address: "5000 Forbes Ave", store: EKEventStore())
        #expect(event.title == "\(match.title) · WhosDown")
        #expect(event.startDate == match.startTime)
        #expect(event.endDate == match.endTime)
        #expect(event.location == "\(match.venueName), 5000 Forbes Ave")
        #expect(event.notes == match.notes)
        #expect(CalendarEventBuilder.event(for: match, address: nil, store: EKEventStore()).location == match.venueName)
    }
    @Test func onlyHostAndApprovedPlayersBeforeStart() {
        var match = Match.sample()
        let now = match.startTime.addingTimeInterval(-1)
        #expect(CalendarEventBuilder.canAdd(match, userId: match.hostId, approved: false, now: now))
        #expect(CalendarEventBuilder.canAdd(match, userId: "sam", approved: true, now: now))
        #expect(!CalendarEventBuilder.canAdd(match, userId: "sam", approved: false, now: now))
        #expect(!CalendarEventBuilder.canAdd(match, userId: nil, approved: true, now: now))
        #expect(!CalendarEventBuilder.canAdd(match, userId: match.hostId, approved: true, now: match.startTime))
        match.status = .cancelled
        #expect(!CalendarEventBuilder.canAdd(match, userId: match.hostId, approved: true, now: now))
    }
}
