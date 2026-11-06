import Foundation
import Testing
@testable import WhosDown

/// 1.13 and 1.14: which join control a Player sees.
struct JoinRulesTests {
    private func context(
        isGuest: Bool = false,
        isHost: Bool = false,
        joinType: JoinType = .open,
        isFull: Bool = false,
        waitlistEnabled: Bool = true,
        matchStatus: MatchStatus = .scheduled,
        hasStarted: Bool = false,
        rsvpStatus: RSVPStatus? = nil
    ) -> JoinContext {
        JoinContext(
            isGuest: isGuest, isHost: isHost, joinType: joinType, isFull: isFull,
            waitlistEnabled: waitlistEnabled, matchStatus: matchStatus, hasStarted: hasStarted,
            rsvpStatus: rsvpStatus
        )
    }

    @Test func openMatchShowsJoin() {
        #expect(JoinRules.action(for: context()) == .join)
        #expect(JoinRules.action(for: context(rsvpStatus: .left)) == .join)
    }

    @Test func approvalMatchShowsRequest() {
        #expect(JoinRules.action(for: context(joinType: .approvalRequired)) == .requestToJoin)
    }

    @Test func fullMatchShowsWaitlistOrFull() {
        #expect(JoinRules.action(for: context(isFull: true)) == .fullWaitlist)
        #expect(JoinRules.action(for: context(isFull: true, waitlistEnabled: false)) == .full)
    }

    @Test func hostNeverSeesJoin() {
        #expect(JoinRules.action(for: context(isHost: true)) == .manage)
        #expect(JoinRules.action(for: context(isHost: true, joinType: .approvalRequired, isFull: true)) == .manage)
    }

    @Test func guestStillGetsTheActionSoTheGateCanOpen() {
        #expect(JoinRules.action(for: context(isGuest: true)) == .join)
        #expect(JoinRules.action(for: context(isGuest: true, joinType: .approvalRequired)) == .requestToJoin)
    }

    @Test func existingRSVPReplacesTheButton() {
        #expect(JoinRules.action(for: context(rsvpStatus: .pending)) == .status(.pending))
        #expect(JoinRules.action(for: context(rsvpStatus: .approved)) == .status(.approved))
        #expect(JoinRules.action(for: context(rsvpStatus: .declined)) == .status(.declined))
        #expect(JoinRules.action(for: context(rsvpStatus: .waitlisted)) == .status(.waitlisted))
    }

    @Test func startedOrCancelledClosesTheButton() {
        #expect(JoinRules.action(for: context(hasStarted: true)) == .none)
        #expect(JoinRules.action(for: context(matchStatus: .cancelled)) == .none)
        #expect(JoinRules.action(for: context(hasStarted: true, rsvpStatus: .approved)) == .status(.approved))
    }

    @Test func noteIsTrimmedAndCapped() {
        #expect(JoinRules.cleanedNote("  see you  ") == "see you")
        #expect(JoinRules.cleanedNote("   ") == nil)
        #expect(JoinRules.cleanedNote(String(repeating: "a", count: 301)) == nil)
        #expect(JoinRules.cleanedNote(String(repeating: "a", count: 300))?.count == 300)
    }
}
