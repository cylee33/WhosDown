import Foundation
import Testing
@testable import WhosDown

struct MyMatchesSorterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func match(id: String, startsInHours: Double, hoursLong: Double = 1.5, status: MatchStatus = .scheduled, hostId: String = "host") -> Match {
        var match = Match.sample(id: id, startsInHours: 0)
        let start = now.addingTimeInterval(startsInHours * 3600)
        match.startTime = start
        match.endTime = start.addingTimeInterval(hoursLong * 3600)
        match.status = status
        match.hostId = hostId
        return match
    }

    private func rsvp(_ status: RSVPStatus, checkedIn: Bool = false, attended: Bool? = nil) -> RSVP {
        var rsvp = RSVP.sample("me", "Me", minutesAgo: 1)
        rsvp.status = status
        rsvp.checkedIn = checkedIn
        rsvp.attended = attended
        return rsvp
    }

    @Test func upcomingIsSoonestAndSkipsLeftEndedAndCancelled() {
        let entries = [
            MatchEntry(match: match(id: "later", startsInHours: 5), rsvp: rsvp(.approved)),
            MatchEntry(match: match(id: "soon", startsInHours: 1), rsvp: rsvp(.pending)),
            MatchEntry(match: match(id: "left", startsInHours: 2), rsvp: rsvp(.left)),
            MatchEntry(match: match(id: "over", startsInHours: -3), rsvp: rsvp(.approved)),
            MatchEntry(match: match(id: "cancelled", startsInHours: 2, status: .cancelled), rsvp: rsvp(.approved)),
        ]
        #expect(MyMatchesSorter.upcoming(entries, now: now).map(\.id) == ["soon", "later"])
    }

    @Test func hostingSkipsEnded() {
        let matches = [
            match(id: "b", startsInHours: 4),
            match(id: "a", startsInHours: 1),
            match(id: "old", startsInHours: -2),
        ]
        #expect(MyMatchesSorter.hosting(matches, now: now).map(\.id) == ["a", "b"])
    }

    @Test func pastGroupsByMonthNewestFirstAndCountsAttended() {
        let september = match(id: "sep", startsInHours: -24 * 40)
        let august = match(id: "aug", startsInHours: -24 * 70)
        let entries = [
            MatchEntry(match: september, rsvp: rsvp(.approved, checkedIn: true, attended: true)),
            MatchEntry(match: august, rsvp: rsvp(.approved, checkedIn: true, attended: false)),
            MatchEntry(match: match(id: "declined", startsInHours: -5), rsvp: rsvp(.declined)),
        ]
        let months = MyMatchesSorter.past(entries: entries, hosted: [], userId: "me", now: now, calendar: calendar)
        #expect(months.map(\.matchCount) == [1, 1])
        #expect(months[0].start > months[1].start)
        #expect(months[0].attendedCount == 1)
        #expect(months[1].attendedCount == 0)
    }

    @Test func pastBadges() {
        let played = match(id: "m", startsInHours: -3)
        #expect(MyMatchesSorter.pastBadge(match: played, rsvp: rsvp(.approved, checkedIn: true, attended: true), isHost: false) == .attended)
        #expect(MyMatchesSorter.pastBadge(match: played, rsvp: rsvp(.approved, checkedIn: true, attended: false), isHost: false) == .missed)
        #expect(MyMatchesSorter.pastBadge(match: played, rsvp: rsvp(.approved), isHost: false) == .notCheckedIn)
        #expect(MyMatchesSorter.pastBadge(match: match(id: "c", startsInHours: -3, status: .cancelled), rsvp: nil, isHost: true) == .cancelled)
        #expect(MyMatchesSorter.pastBadge(match: played, rsvp: nil, isHost: true) == .hosted)
    }
}
