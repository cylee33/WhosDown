import Foundation

/// What H09 offers a Player (1.13, 1.14). Waitlist labels are shown here; joining the line is 1.17.
nonisolated enum JoinAction: Equatable, Sendable {
    case join
    case requestToJoin
    /// Full, and the Match has a waitlist.
    case fullWaitlist
    /// Full, with no waitlist (the button is disabled).
    case full
    /// The Host's own Match.
    case manage
    /// An RSVP already exists, so the status card replaces the button.
    case status(RSVPStatus)
    case none
}

/// The facts `JoinRules` needs. Views pass the live Match and the Player's own RSVP.
nonisolated struct JoinContext: Equatable, Sendable {
    var isGuest: Bool
    var isHost: Bool
    var joinType: JoinType
    var isFull: Bool
    var waitlistEnabled: Bool
    var matchStatus: MatchStatus
    var hasStarted: Bool
    /// Nil when the Player has no RSVP.
    var rsvpStatus: RSVPStatus?
}

nonisolated enum JoinRules {
    /// Which control H09 shows (1.13 rules 1 and 8, 1.14 rules 1–5 and 17).
    static func action(for context: JoinContext) -> JoinAction {
        if context.isHost { return .manage }
        if context.matchStatus == .cancelled || context.hasStarted {
            if let status = context.rsvpStatus, status != .left { return .status(status) }
            return .none
        }
        if let status = context.rsvpStatus, status != .left {
            return .status(status)
        }
        if context.isFull {
            return context.waitlistEnabled ? .fullWaitlist : .full
        }
        switch context.joinType {
        case .open: return .join
        case .approvalRequired: return .requestToJoin
        }
    }

    static let noteLimit = 300

    /// Empty notes are saved as null (1.14 rule 10). Too-long notes are refused.
    static func cleanedNote(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.count <= noteLimit ? trimmed : nil
    }
}
