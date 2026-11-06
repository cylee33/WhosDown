import Foundation

/// One Match on the My Matches lists, with the Player's RSVP when they have one (1.19).
struct MatchEntry: Equatable, Identifiable, Sendable {
    var match: Match
    var rsvp: RSVP?

    var id: String { match.id ?? match.title }
}

enum PastBadge: Equatable, Sendable {
    case attended, missed, notCheckedIn, cancelled, hosted

    var title: String {
        switch self {
        case .attended: "Attended"
        case .missed: "Didn't attend"
        case .notCheckedIn: "Not checked in"
        case .cancelled: "Cancelled"
        case .hosted: "Hosted"
        }
    }
}

struct PastMonth: Equatable, Identifiable, Sendable {
    var start: Date
    var title: String
    var matchCount: Int
    var attendedCount: Int
    var rows: [MatchEntry]

    var id: Date { start }
}

/// Upcoming, hosting, and past splits (1.19). "Now" is passed in so tests stay fixed.
enum MyMatchesSorter {
    static func upcoming(_ entries: [MatchEntry], now: Date = .now) -> [MatchEntry] {
        entries
            .filter { entry in
                guard let status = entry.rsvp?.status, showsInUpcoming(status) else { return false }
                return entry.match.status == .scheduled && entry.match.endTime > now
            }
            .sorted { $0.match.startTime < $1.match.startTime }
    }

    static func hosting(_ matches: [Match], now: Date = .now) -> [Match] {
        matches
            .filter { $0.status == .scheduled && $0.endTime > now }
            .sorted { $0.startTime < $1.startTime }
    }

    static func past(
        entries: [MatchEntry], hosted: [Match], userId: String, now: Date = .now, calendar: Calendar = .current
    ) -> [PastMonth] {
        var byId: [String: MatchEntry] = [:]
        for entry in entries where isPast(entry.match, now: now) && entry.rsvp?.status == .approved {
            if let id = entry.match.id { byId[id] = entry }
        }
        for match in hosted where isPast(match, now: now) {
            guard let id = match.id, match.hostId == userId else { continue }
            if byId[id] == nil { byId[id] = MatchEntry(match: match, rsvp: nil) }
        }
        let rows = byId.values.sorted { $0.match.startTime > $1.match.startTime }
        let grouped = Dictionary(grouping: rows) { calendar.dateInterval(of: .month, for: $0.match.startTime)?.start ?? $0.match.startTime }
        return grouped.keys.sorted(by: >).map { start in
            let monthRows = grouped[start] ?? []
            let attended = monthRows.filter { $0.rsvp?.checkedIn == true && $0.rsvp?.attended == true }.count
            return PastMonth(
                start: start,
                title: start.formatted(.dateTime.month(.wide)),
                matchCount: monthRows.count,
                attendedCount: attended,
                rows: monthRows
            )
        }
    }

    static func pastBadge(match: Match, rsvp: RSVP?, isHost: Bool) -> PastBadge {
        if match.status == .cancelled { return .cancelled }
        if isHost { return .hosted }
        if rsvp?.checkedIn == true { return rsvp?.attended == true ? .attended : .missed }
        return .notCheckedIn
    }

    /// Check-in is open from the start until 48 hours after the end (1.27). Shown on past hosted rows.
    static func checkInOpen(_ match: Match, now: Date = .now) -> Bool {
        match.status == .scheduled && match.startTime <= now && now <= match.endTime.addingTimeInterval(48 * 3600)
    }

    static func waitlistPosition(userId: String, match: Match) -> Int? {
        guard let index = match.waitlistIds.firstIndex(of: userId) else { return nil }
        return index + 1
    }

    private static func showsInUpcoming(_ status: RSVPStatus) -> Bool {
        switch status {
        case .approved, .pending, .waitlisted, .declined: true
        case .left: false
        }
    }

    private static func isPast(_ match: Match, now: Date) -> Bool {
        match.status == .cancelled || match.endTime <= now
    }
}
