import Foundation

/// H27 and H28 (1.19).
@Observable
final class MyMatchesViewModel {
    enum Segment: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case hosting = "Hosting"
        case past = "Past"
        var id: String { rawValue }
    }

    var segment: Segment = .upcoming
    private(set) var upcoming: [MatchEntry] = []
    private(set) var hosting: [Match] = []
    private(set) var past: [PastMonth] = []
    private(set) var errorMessage: String?
    private var entries: [MatchEntry] = []
    private var hosted: [Match] = []
    private var now = Date.now

    let userId: String
    private let matches: MatchRepository
    private let rsvps: RSVPRepository

    init(userId: String, matches: MatchRepository, rsvps: RSVPRepository) {
        self.userId = userId
        self.matches = matches
        self.rsvps = rsvps
    }

    func start() async {
        async let hostedTask: Void = listenHosted()
        async let refreshTask: Void = refreshLoop()
        await load()
        _ = await (hostedTask, refreshTask)
    }

    func load() async {
        do {
            let mine = try await rsvps.myRSVPs(userId: userId)
            let ids = Array(Set(mine.map(\.matchId)))
            let fetched = ids.isEmpty ? [] : try await matches.matches(ids: ids)
            let byId = Dictionary(uniqueKeysWithValues: fetched.compactMap { match in match.id.map { ($0, match) } })
            entries = mine.compactMap { item in
                byId[item.matchId].map { MatchEntry(match: $0, rsvp: item.rsvp) }
            }
            apply()
        } catch {
            errorMessage = "Couldn't load your Matches."
        }
    }

    private func listenHosted() async {
        do {
            for try await value in matches.hostedChanges(hostId: userId) {
                hosted = value
                apply()
            }
        } catch {
            errorMessage = "Couldn't load Matches you host."
        }
    }

    private func refreshLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            now = .now
            apply()
        }
    }

    private func apply() {
        upcoming = MyMatchesSorter.upcoming(entries, now: now)
        hosting = MyMatchesSorter.hosting(hosted, now: now)
        past = MyMatchesSorter.past(entries: entries, hosted: hosted, userId: userId, now: now)
    }
}
