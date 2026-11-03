import Foundation

/// Discover filters (1.7). Distance isn't here: it's the search radius, saved separately (rule 3).
nonisolated struct MatchFilter: Equatable, Sendable {
    /// Rule 2: one time choice, or any time.
    enum TimeWindow: Equatable, Sendable {
        case any, now, tonight, tomorrow
        /// Days (inclusive) and a time-of-day window in minutes after midnight; nil means "Any".
        case custom(firstDay: Date?, lastDay: Date?, fromMinute: Int?, toMinute: Int?)
    }

    static let radiusRange = 0.5...25.0
    static let defaultRadiusMiles = 3.0

    var sports: Set<Sport> = []
    var time: TimeWindow = .any
    var skillLevels: Set<SkillLevel> = []
    /// Nil means any join type (rule 5).
    var joinType: JoinType?

    /// The "Filters N" count (rule 9).
    var activeCount: Int {
        [!sports.isEmpty, time != .any, !skillLevels.isEmpty, joinType != nil].filter { $0 }.count
    }

    func includes(_ match: Match, now: Date = .now, calendar: Calendar = .current) -> Bool {
        if !sports.isEmpty && !sports.contains(match.sport) { return false }
        // Rule 4: a Match for All Levels suits every skill choice.
        if !skillLevels.isEmpty && match.skillLevel != .allLevels && !skillLevels.contains(match.skillLevel) { return false }
        if let joinType, match.joinType != joinType { return false }
        return fits(match, now: now, calendar: calendar)
    }

    private func fits(_ match: Match, now: Date, calendar: Calendar) -> Bool {
        let start = match.startTime
        switch time {
        case .any:
            return true
        case .now:
            // In progress, or starting within the next hour.
            return start <= now.addingTimeInterval(3600) && match.endTime > now
        case .tonight:
            let today = calendar.startOfDay(for: now)
            guard let fivePM = calendar.date(byAdding: .hour, value: 17, to: today),
                  let midnight = calendar.date(byAdding: .day, value: 1, to: today) else { return false }
            return start >= fivePM && start < midnight
        case .tomorrow:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return false }
            return calendar.isDate(start, inSameDayAs: tomorrow)
        case let .custom(firstDay, lastDay, fromMinute, toMinute):
            let day = calendar.startOfDay(for: start)
            if let firstDay, day < calendar.startOfDay(for: firstDay) { return false }
            if let lastDay, day > calendar.startOfDay(for: lastDay) { return false }
            let minute = calendar.component(.hour, from: start) * 60 + calendar.component(.minute, from: start)
            if let fromMinute, minute < fromMinute { return false }
            if let toMinute, minute > toMinute { return false }
            return true
        }
    }
}

/// Text for Match rows, pins, and details (1.5, 1.6, 1.8). All times in the phone's time zone (D42).
nonisolated enum MatchFormatting {
    /// Started and not yet over.
    static func isNow(_ match: Match, now: Date = .now) -> Bool {
        match.startTime <= now && match.endTime > now
    }

    /// "Now", "7:00 PM" (today), "Tomorrow · 6:00 PM", or "Sat, Nov 8 · 6:00 PM" (1.6 rule 8).
    static func when(_ match: Match, now: Date = .now, calendar: Calendar = .current) -> String {
        if isNow(match, now: now) { return "Now" }
        let time = match.startTime.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(match.startTime, inSameDayAs: now) { return time }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(match.startTime, inSameDayAs: tomorrow) {
            return "Tomorrow · \(time)"
        }
        return "\(match.startTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(time)"
    }

    /// "Today · 7:00–8:30 PM" for Match details (H09).
    static func dateRange(_ match: Match, now: Date = .now, calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(match.startTime, inSameDayAs: now) { day = "Today" }
        else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(match.startTime, inSameDayAs: tomorrow) { day = "Tomorrow" }
        else { day = match.startTime.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) }
        return "\(day) · \(match.startTime.formatted(date: .omitted, time: .shortened))–\(match.endTime.formatted(date: .omitted, time: .shortened))"
    }

    /// "Free", "$5", or "$7.50".
    static func price(_ match: Match) -> String {
        guard match.priceCents > 0 else { return "Free" }
        return match.priceCents % 100 == 0 ? "$\(match.priceCents / 100)" : String(format: "$%.2f", Double(match.priceCents) / 100)
    }

    /// "12/14", or "Full" when no spots are left (1.6 rule 3).
    static func count(_ match: Match) -> String {
        match.isFull ? "Full" : "\(match.joinedCount)/\(match.playerLimit)"
    }

    /// "12 / 14 joined · 2 spots left" or "14 / 14 joined · Full" (H09, 1.8 rule 4).
    static func spots(_ match: Match) -> String {
        let left = match.spotsLeft
        let tail = left == 0 ? "Full" : "\(left) \(left == 1 ? "spot" : "spots") left"
        return "\(match.joinedCount) / \(match.playerLimit) joined · \(tail)"
    }

    /// Soonest first, with Matches happening now at the top (1.6 rule 1).
    static func sortedForList(_ matches: [Match], now: Date = .now) -> [Match] {
        matches.sorted { a, b in
            let aNow = isNow(a, now: now), bNow = isNow(b, now: now)
            if aNow != bNow { return aNow }
            return a.startTime < b.startTime
        }
    }
}
