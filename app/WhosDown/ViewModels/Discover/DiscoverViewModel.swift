import Foundation

/// Discover map (1.5), list (1.6), and filters (1.7) share this one view model and one nearby query.
@Observable
final class DiscoverViewModel {
    enum Mode: Hashable { case map, list }
    enum LoadState: Equatable { case loading, loaded, failed(String) }

    var mode: Mode = .map
    private(set) var center: Coordinate = .cmu
    /// The Player's own location, if they allowed it (1.5 rule 1). Nil shows the "Turn on location" hint.
    private(set) var userLocation: Coordinate?
    private(set) var radiusMiles = MatchFilter.defaultRadiusMiles
    private(set) var filter = MatchFilter()
    private(set) var nearbyMatches: [Match] = []
    private(set) var nextUp: Match?
    private(set) var state: LoadState = .loading

    private let userId: String?
    private let isGuest: Bool
    private let matchRepository: MatchRepository
    private let rsvps: RSVPRepository
    private let users: UserRepository
    private let location: LocationService

    init(
        userId: String?, isGuest: Bool, matches: MatchRepository, rsvps: RSVPRepository,
        users: UserRepository, location: LocationService
    ) {
        self.userId = userId
        self.isGuest = isGuest
        self.matchRepository = matches
        self.rsvps = rsvps
        self.users = users
        self.location = location
    }

    var radiusMeters: Double { radiusMiles * 1609.344 }

    /// Nearby Matches that pass the filters (map pins and list rows).
    var visibleMatches: [Match] {
        MatchFormatting.sortedForList(nearbyMatches.filter { filter.includes($0) })
    }

    /// One pin per Venue; a Venue with several Matches shows a count (1.5 rule 3).
    var pins: [VenuePin] {
        Dictionary(grouping: visibleMatches, by: \.venueId)
            .map { VenuePin(venueId: $0.key, matches: MatchFormatting.sortedForList($0.value)) }
            .sorted { $0.venueId < $1.venueId }
    }

    /// First load: radius from settings, the Player's location (or CMU), Matches, and "Next up".
    func load() async {
        if let userId, !isGuest, let saved = try? await users.settings(userId: userId)?.searchRadiusMiles {
            radiusMiles = min(max(saved, MatchFilter.radiusRange.lowerBound), MatchFilter.radiusRange.upperBound)
        }
        userLocation = await location.currentLocation()
        center = userLocation ?? .cmu
        await refresh()
        await loadNextUp()
    }

    /// Re-runs the nearby query around the current center (pull to refresh, 1.6 rule 6).
    func refresh() async {
        do {
            nearbyMatches = try await matchRepository.nearby(center: center, radiusMeters: radiusMeters)
            state = .loaded
        } catch {
            state = .failed("Couldn't load Matches. Check your connection and try again.")
        }
    }

    /// The map stopped moving (1.5 rule 7): search again around the new center if it moved a quarter of the radius.
    func mapSettled(at newCenter: Coordinate) async {
        guard VenueRules.distanceMeters(newCenter, center) > radiusMeters / 4 else { return }
        center = newCenter
        await refresh()
    }

    /// "Back to my location".
    func recenter() async {
        userLocation = await location.currentLocation() ?? userLocation
        center = userLocation ?? .cmu
        await refresh()
    }

    // MARK: - Filters (1.7)

    /// How many nearby Matches a draft filter would show ("Show N Matches", rule 6).
    func count(with draft: MatchFilter, radiusMiles draftRadius: Double) -> Int {
        let radius = draftRadius * 1609.344
        return nearbyMatches.filter { draft.includes($0) && VenueRules.distanceMeters($0.location, center) <= radius }.count
    }

    /// Applies the sheet. Only the distance is saved (rules 3 and 7); a bigger radius searches again.
    func apply(_ newFilter: MatchFilter, radiusMiles newRadius: Double) async {
        filter = newFilter
        guard MatchFilter.radiusRange.contains(newRadius), newRadius != radiusMiles else { return }
        let grew = newRadius > radiusMiles
        radiusMiles = newRadius
        if let userId, !isGuest { try? await users.saveSearchRadius(userId: userId, miles: newRadius) }
        if grew {
            await refresh()
        } else {
            nearbyMatches = nearbyMatches.filter { VenueRules.distanceMeters($0.location, center) <= radiusMeters }
        }
    }

    /// The quick chips under the list title (1.6 rule 4).
    func setSportShortcut(_ sport: Sport?) {
        filter.sports = sport.map { [$0] } ?? []
    }

    func toggleTonight() {
        filter.time = filter.time == .tonight ? .any : .tonight
    }

    func distanceText(to match: Match) -> String {
        VenueRules.milesText(VenueRules.distanceMeters(userLocation ?? center, match.location))
    }

    // MARK: - Next up (1.5 rule 6)

    private func loadNextUp() async {
        guard let userId, !isGuest,
              let ids = try? await rsvps.myApprovedMatchIds(userId: userId), !ids.isEmpty,
              let matches = try? await matchRepository.matches(ids: ids) else {
            nextUp = nil
            return
        }
        let now = Date.now
        nextUp = matches
            .filter { $0.status == .scheduled && $0.endTime > now }
            .min { $0.startTime < $1.startTime }
    }
}

/// A map pin for one Venue and the Matches there.
nonisolated struct VenuePin: Identifiable, Equatable, Sendable {
    let venueId: String
    let matches: [Match]
    var id: String { venueId }
    var location: Coordinate { matches[0].location }
    var sport: Sport { matches[0].sport }
    var isFull: Bool { matches.allSatisfy(\.isFull) }
}
