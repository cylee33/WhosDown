import Foundation

/// H09 Match details (1.8): the Match, live, plus the Host's Reliability and the distance.
/// Phase 4 adds the join / request / waitlist / leave actions.
@Observable
final class MatchDetailViewModel {
    enum State: Equatable { case loading, loaded, missing, failed }

    private(set) var match: Match?
    private(set) var hostReliability: Reliability?
    private(set) var distance: String?
    private(set) var state: State = .loading

    let matchId: String
    private let userId: String?
    private let matches: MatchRepository
    private let reliability: ReliabilityRepository
    private let location: LocationService

    init(matchId: String, userId: String?, matches: MatchRepository, reliability: ReliabilityRepository, location: LocationService) {
        self.matchId = matchId
        self.userId = userId
        self.matches = matches
        self.reliability = reliability
        self.location = location
    }

    var isHost: Bool { match.map { $0.hostId == userId } ?? false }
    var hasEnded: Bool { match.map { $0.endTime <= .now } ?? false }
    var isCancelled: Bool { match?.status == .cancelled }

    /// "Field reserved 6:45–8:45 PM" etc.: only the facts that are set (rule 3).
    var venueFacts: [String] {
        guard let match else { return [] }
        var facts = [match.isIndoor ? "Indoor" : "Outdoor", match.surface.capitalized]
        if match.hasLights { facts.append("Lights on") }
        if match.fieldReserved { facts.append("Field reserved" + (match.reservationWindow.map { " \($0)" } ?? "")) }
        return facts
    }

    /// Follows the Match for as long as the screen is open (rule 1).
    func start() async {
        do {
            for try await value in matches.matchChanges(matchId: matchId) {
                guard let value else {
                    match = nil
                    state = .missing
                    continue
                }
                let hostChanged = match?.hostId != value.hostId
                match = value
                state = .loaded
                if hostChanged { await loadExtras(for: value) }
            }
        } catch {
            if match == nil { state = .failed }
        }
    }

    private func loadExtras(for match: Match) async {
        hostReliability = try? await reliability.reliability(userId: match.hostId)
        if let here = await location.currentLocation() {
            distance = VenueRules.milesText(VenueRules.distanceMeters(here, match.location))
        }
    }
}
