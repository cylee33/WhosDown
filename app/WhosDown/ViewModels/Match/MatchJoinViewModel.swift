import Foundation

/// Join, request, and leave for one Match (1.13, 1.14, 1.16).
@Observable
final class MatchJoinViewModel {
    private(set) var myRSVP: RSVP?
    private(set) var isWorking = false
    var errorMessage: String?
    var note = ""
    var showReview = false
    var showLeave = false

    let matchId: String
    private let userId: String?
    private let rsvps: RSVPRepository

    init(matchId: String, userId: String?, rsvps: RSVPRepository) {
        self.matchId = matchId
        self.userId = userId
        self.rsvps = rsvps
    }

    func start() async {
        guard let userId else { return }
        do {
            for try await value in rsvps.myRSVPChanges(matchId: matchId, userId: userId) {
                myRSVP = value
            }
        } catch {
            errorMessage = "Couldn't load your RSVP."
        }
    }

    func action(for match: Match, isGuest: Bool, userId: String?) -> JoinAction {
        JoinRules.action(for: JoinContext(
            isGuest: isGuest,
            isHost: match.hostId == userId,
            joinType: match.joinType,
            isFull: match.isFull,
            waitlistEnabled: match.waitlistEnabled,
            matchStatus: match.status,
            hasStarted: match.startTime <= .now,
            rsvpStatus: myRSVP?.status
        ))
    }

    func join(player: UserProfile?, match: Match) async {
        guard let player else { return }
        await run {
            try await self.rsvps.joinOpen(matchId: match.id ?? self.matchId, player: player, sport: match.sport)
        }
    }

    func sendRequest(player: UserProfile?, match: Match) async {
        guard let player else { return }
        await run {
            try await self.rsvps.requestToJoin(
                matchId: match.id ?? self.matchId, player: player, sport: match.sport, note: self.note
            )
            self.showReview = false
            self.note = ""
        }
    }

    func leave() async {
        guard let userId else { return }
        await run {
            try await self.rsvps.leave(matchId: self.matchId, userId: userId)
            self.showLeave = false
        }
    }

    private func run(_ work: () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await work()
        } catch let error as RSVPWriteError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
