import Foundation

nonisolated struct MatchReminder: Equatable, Sendable {
    let matchId: String
    let title: String
    let venue: String
    let fireDate: Date
    var identifier: String { "match-\(matchId)" }
}

nonisolated enum ReminderPlanner {
    static func plan(matches: [Match], approvedIds: Set<String>, userId: String, now: Date = .now) -> [MatchReminder] {
        var seen = Set<String>()
        return matches.sorted { $0.startTime < $1.startTime }.compactMap { match in
            guard let id = match.id, match.status == .scheduled,
                  match.hostId == userId || approvedIds.contains(id),
                  match.startTime.addingTimeInterval(-3600) > now,
                  seen.insert(id).inserted else { return nil }
            return MatchReminder(matchId: id, title: "\(match.title) starts in 1 hour", venue: match.venueName,
                                 fireDate: match.startTime.addingTimeInterval(-3600))
        }
        // iOS allows 64 pending requests per app; keep the soonest ones.
        .prefix(64).map { $0 }
    }
}
