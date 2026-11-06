import Foundation

/// H20 and H21 (1.15): the Host's Match, its Join requests, and approve / decline.
@Observable
final class HostDashboardViewModel {
    private(set) var match: Match?
    private(set) var requests: [RSVP] = []
    private(set) var waitlist: [RSVP] = []
    private(set) var reliability: [String: Reliability] = [:]
    private(set) var lastMessage: String?
    var errorMessage: String?
    var declining: RSVP?

    let matchId: String
    private let hostId: String
    private let matches: MatchRepository
    private let rsvps: RSVPRepository
    private let reliabilityRepo: ReliabilityRepository
    private let chat: ChatRepository

    init(
        matchId: String, hostId: String, matches: MatchRepository, rsvps: RSVPRepository,
        reliability: ReliabilityRepository, chat: ChatRepository
    ) {
        self.matchId = matchId
        self.hostId = hostId
        self.matches = matches
        self.rsvps = rsvps
        self.reliabilityRepo = reliability
        self.chat = chat
    }

    var isFull: Bool { match?.isFull ?? false }

    func start() async {
        async let matchTask: Void = listenMatch()
        async let requestTask: Void = listenRequests()
        async let waitTask: Void = listenWaitlist()
        async let chatTask: Void = listenChat()
        _ = await (matchTask, requestTask, waitTask, chatTask)
    }

    func approveWaitlist(_ request: RSVP) async {
        guard !isFull else { return }
        do {
            try await rsvps.approveFromWaitlist(matchId: matchId, userId: request.userId, hostId: hostId)
        } catch {
            errorMessage = "Couldn't approve that Player."
        }
    }

    func approve(_ request: RSVP) async {
        guard !isFull else { return }
        do {
            try await rsvps.approve(matchId: matchId, userId: request.userId, hostId: hostId)
        } catch {
            errorMessage = (error as? RSVPWriteError)?.errorDescription ?? "Couldn't approve that request."
        }
    }

    func decline(_ request: RSVP, message: String) async {
        do {
            try await rsvps.decline(matchId: matchId, userId: request.userId, hostId: hostId, message: message)
            declining = nil
        } catch {
            errorMessage = (error as? RSVPWriteError)?.errorDescription ?? "Couldn't decline that request."
        }
    }

    private func listenMatch() async {
        do {
            for try await value in matches.matchChanges(matchId: matchId) {
                match = value
            }
        } catch {
            errorMessage = "Couldn't load this Match."
        }
    }

    private func listenRequests() async {
        do {
            for try await value in rsvps.pendingChanges(matchId: matchId) {
                requests = value
                for request in value where reliability[request.userId] == nil {
                    reliability[request.userId] = try? await reliabilityRepo.reliability(userId: request.userId)
                }
            }
        } catch {
            errorMessage = "Couldn't load Join requests."
        }
    }

    private func listenWaitlist() async {
        do {
            for try await value in rsvps.waitlistedChanges(matchId: matchId) {
                let order = match?.waitlistIds ?? []
                waitlist = value.sorted { a, b in
                    (order.firstIndex(of: a.userId) ?? 0) < (order.firstIndex(of: b.userId) ?? 0)
                }
            }
        } catch {
            errorMessage = "Couldn't load the waitlist."
        }
    }

    private func listenChat() async {
        do {
            for try await conversation in chat.conversationChanges(matchId: matchId) {
                lastMessage = conversation?.lastMessageText
            }
        } catch {
            lastMessage = nil
        }
    }
}
