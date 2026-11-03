import Foundation

/// H11 Who's going (1.10): approved Players, live, with each one's Reliability (counted once per screen, rule 6).
@Observable
final class RosterViewModel {
    private(set) var players: [RSVP] = []
    private(set) var reliabilities: [String: Reliability] = [:]
    private(set) var errorMessage: String?

    let match: Match
    private let rsvps: RSVPRepository
    private let reliability: ReliabilityRepository

    init(match: Match, rsvps: RSVPRepository, reliability: ReliabilityRepository) {
        self.match = match
        self.rsvps = rsvps
        self.reliability = reliability
    }

    /// "Pickup Soccer · Today 7:00 PM"
    var subtitle: String { "\(match.title) · \(MatchFormatting.when(match))" }

    /// "12 / 14 joined", from the live roster.
    var joinedText: String { "\(players.count) / \(match.playerLimit) joined" }

    /// "Host · 96% reliable" or "94% reliable · All Levels".
    func detail(for rsvp: RSVP) -> String {
        let label = reliabilities[rsvp.userId]?.label ?? "…"
        return rsvp.isHost ? "Host · \(label)" : "\(label) · \(rsvp.skillLevel.displayName)"
    }

    func start() async {
        do {
            for try await roster in rsvps.approvedChanges(matchId: match.id ?? "") {
                players = roster
                await loadMissingReliability()
            }
        } catch {
            errorMessage = "Couldn't load who's going. Check your connection and try again."
        }
    }

    private func loadMissingReliability() async {
        let missing = players.map(\.userId).filter { reliabilities[$0] == nil }
        await withTaskGroup(of: (String, Reliability?).self) { group in
            for userId in missing {
                group.addTask { [reliability] in (userId, try? await reliability.reliability(userId: userId)) }
            }
            for await (userId, value) in group {
                if let value { reliabilities[userId] = value }
            }
        }
    }
}
