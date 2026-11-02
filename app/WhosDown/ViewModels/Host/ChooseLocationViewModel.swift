import Foundation

/// H40 Choose location (1.12): saved Venues near the Host, Apple Maps search, and saving a new place as a Venue.
@Observable
final class ChooseLocationViewModel {
    enum Choice: Equatable {
        case venue(Venue)
        case place(Place)

        var name: String {
            switch self {
            case .venue(let venue): venue.name
            case .place(let place): place.name
            }
        }

        var location: Coordinate {
            switch self {
            case .venue(let venue): venue.location
            case .place(let place): place.location
            }
        }
    }

    var query = ""
    private(set) var center: Coordinate = .cmu
    private(set) var nearbyVenues: [Venue] = []
    private(set) var matchingVenues: [Venue] = []
    private(set) var places: [Place] = []
    private(set) var choice: Choice?
    /// A searched place that isn't a saved Venue yet; the three-question sheet is showing (rule 3).
    var placeNeedingFacts: Place?
    private(set) var isWorking = false
    private(set) var message: String?

    private let userId: String
    private let venues: VenueRepository
    private let placeSearch: PlaceSearchService
    private let location: LocationService

    init(userId: String, venues: VenueRepository, placeSearch: PlaceSearchService, location: LocationService) {
        self.userId = userId
        self.venues = venues
        self.placeSearch = placeSearch
        self.location = location
    }

    /// Saved Venues to show: the nearby list, or the ones matching the typed name (rule 1).
    var suggestedVenues: [Venue] {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nearbyVenues }
        let nearbyMatches = nearbyVenues.filter { $0.name.localizedCaseInsensitiveContains(text) }
        let others = matchingVenues.filter { venue in !nearbyMatches.contains { $0.id == venue.id } }
        return nearbyMatches + others
    }

    /// "Use CMU Soccer Field" (rule 4).
    var useButtonTitle: String { choice.map { "Use \($0.name)" } ?? "Choose a place" }

    func distanceText(to coordinate: Coordinate) -> String {
        VenueRules.milesText(VenueRules.distanceMeters(center, coordinate))
    }

    /// Centers on the Host (or CMU without location, rule 5) and loads saved Venues nearby.
    func load() async {
        center = await location.currentLocation() ?? .cmu
        do {
            nearbyVenues = try await venues.nearby(center: center, radiusMeters: VenueRules.suggestionRadiusMeters)
            message = nil
        } catch {
            message = Self.offlineMessage
        }
    }

    /// Runs when the typed text changes: saved Venues by name, then Apple Maps places (rule 1).
    func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else {
            matchingVenues = []
            places = []
            return
        }
        do {
            matchingVenues = try await venues.search(namePrefix: text)
            let found = try await placeSearch.search(text, near: center)
            guard text == query.trimmingCharacters(in: .whitespaces) else { return }
            // A place that is really a saved Venue shows only once, as the Venue (rule 2).
            let known = nearbyVenues + matchingVenues
            places = found.filter { VenueRules.existingVenue(for: $0, among: known) == nil }
            message = nil
        } catch {
            message = Self.offlineMessage
        }
    }

    func choose(_ venue: Venue) {
        choice = .venue(venue)
    }

    /// A searched place becomes the saved Venue it matches, or asks the three questions first (rules 2–3).
    func choose(_ place: Place) {
        if let existing = VenueRules.existingVenue(for: place, among: nearbyVenues + matchingVenues) {
            choice = .venue(existing)
        } else {
            choice = .place(place)
        }
    }

    /// "Use …": returns the chosen Venue, or opens the three-question sheet for a new place.
    func confirm() -> Venue? {
        switch choice {
        case .venue(let venue): return venue
        case .place(let place):
            placeNeedingFacts = place
            return nil
        case nil: return nil
        }
    }

    /// Saves the new place as a Venue with the Host's answers (W18) and returns it.
    func saveNewVenue(isIndoor: Bool, surface: Surface, hasLights: Bool) async -> Venue? {
        guard let place = placeNeedingFacts, !isWorking else { return nil }
        isWorking = true
        defer { isWorking = false }
        do {
            let venue = try await venues.create(
                VenueDraft(name: place.name, address: place.address, location: place.location,
                           isIndoor: isIndoor, surface: surface, hasLights: hasLights),
                createdBy: userId
            )
            placeNeedingFacts = nil
            choice = .venue(venue)
            return venue
        } catch {
            message = "Couldn't save this place. Check your connection and try again."
            return nil
        }
    }

    private static let offlineMessage = "Search needs a connection."
}
