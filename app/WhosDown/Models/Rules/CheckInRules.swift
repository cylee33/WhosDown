import Foundation

/// Who can be checked in, and when (1.27, D31).
enum CheckInRules {
    static let window: TimeInterval = 48 * 3600

    static func isOpen(_ match: Match, now: Date = .now) -> Bool {
        match.status == .scheduled && match.startTime <= now && now <= match.endTime.addingTimeInterval(window)
    }

    /// Approved Players, Host first. The Host has no switch and is always attended.
    static func rows(_ rsvps: [RSVP]) -> [RSVP] {
        RosterRules.ordered(rsvps.filter { $0.status == .approved })
    }
}
