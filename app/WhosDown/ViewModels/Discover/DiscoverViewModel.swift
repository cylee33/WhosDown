import Foundation

/// Phase 0 placeholder: loads upcoming Matches to prove the app reads the emulator.
/// 1.5 replaces the query with the nearby (geohash) search and adds the map.
@Observable
final class DiscoverViewModel {
    enum State: Equatable {
        case loading
        case loaded([Match])
        case failed(String)
    }

    private(set) var state: State = .loading
    private let matches: MatchRepository

    init(matches: MatchRepository) {
        self.matches = matches
    }

    func load() async {
        do {
            state = .loaded(try await matches.upcomingMatches())
        } catch {
            state = .failed("Couldn't load Matches. Check your connection and try again.")
        }
    }
}
