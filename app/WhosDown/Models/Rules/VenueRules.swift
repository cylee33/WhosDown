import Foundation

/// A place found with Apple Maps search that may or may not be a saved Venue yet (1.12).
nonisolated struct Place: Equatable, Hashable, Sendable {
    var name: String
    var address: String
    var location: Coordinate
}

extension Coordinate {
    /// CMU Soccer Field: the map's center when the Player hasn't shared their location (1.4 rule 6, 1.12 rule 5).
    nonisolated static let cmu = Coordinate(latitude: 40.4433, longitude: -79.9436)
}

/// Rules for choosing a Venue (1.12).
nonisolated enum VenueRules {
    /// The Host's search area for saved Venues: 5 miles.
    static let suggestionRadiusMeters = 8046.72
    /// A place this close to a saved Venue with a similar name is the same Venue (rule 2).
    static let sameVenueMeters = 50.0

    static func distanceMeters(_ a: Coordinate, _ b: Coordinate) -> Double {
        Geohash.distance(fromLatitude: a.latitude, longitude: a.longitude, toLatitude: b.latitude, longitude: b.longitude)
    }

    /// Venues within the radius, nearest first (rule 1).
    static func sortedByDistance(_ venues: [Venue], from center: Coordinate, within radius: Double) -> [Venue] {
        venues
            .map { ($0, distanceMeters($0.location, center)) }
            .filter { $0.1 <= radius }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    /// The saved Venue a searched place really is, if any (rule 2): within 50 m and a similar name.
    static func existingVenue(for place: Place, among venues: [Venue]) -> Venue? {
        venues
            .filter { distanceMeters($0.location, place.location) <= sameVenueMeters && namesMatch($0.name, place.name) }
            .min { distanceMeters($0.location, place.location) < distanceMeters($1.location, place.location) }
    }

    /// "Schenley Oval" matches "Schenley Oval Sports Complex" and "schenley oval", but not "Schenley Park".
    static func namesMatch(_ a: String, _ b: String) -> Bool {
        let x = normalized(a), y = normalized(b)
        guard !x.isEmpty, !y.isEmpty else { return false }
        return x == y || x.contains(y) || y.contains(x)
    }

    /// "0.4 mi" or "1.2 mi" (one decimal), as on H40.
    static func milesText(_ meters: Double) -> String {
        String(format: "%.1f mi", meters / 1609.344)
    }

    /// "Outdoor · Turf · Lights", as on H40 and H18.
    static func factsLine(_ venue: Venue) -> String {
        [venue.isIndoor ? "Indoor" : "Outdoor", venue.surface.capitalized, venue.hasLights ? "Lights" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private static func normalized(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
