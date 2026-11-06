import Foundation

/// What happens when an approved spot opens (ADR-0008). Phase 4 only calls this hook;
/// 1.17 fills in who gets the spot.
nonisolated enum WaitlistRules {
    /// The user IDs, in line order, who should be approved because spots opened.
    /// Open Matches promote the first in line. Approval-required Matches promote nobody;
    /// the Host is notified instead when anyone is waiting.
    static func promotedIds(joinType: JoinType, waitlistIds: [String], spotsOpened: Int, hasStarted: Bool) -> [String] {
        guard joinType == .open, !hasStarted, spotsOpened > 0 else { return [] }
        return Array(waitlistIds.prefix(spotsOpened))
    }

    static let cap = 50
}
