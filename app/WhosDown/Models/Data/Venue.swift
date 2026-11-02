import Foundation

/// A latitude/longitude pair, stored as a map so it decodes without Firestore's GeoPoint.
nonisolated struct Coordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
}

/// `venues/{venueId}`: a real place where Matches are played.
nonisolated struct Venue: Codable, Identifiable, Hashable, Sendable {
    /// The Firestore document ID. Not stored in the document; repositories fill it in (`FirestoreDocument`).
    var id: String?
    var name: String
    var nameLowercase: String
    var address: String
    var location: Coordinate
    var geohash: String
    var isIndoor: Bool
    var surface: String
    var hasLights: Bool
    var sports: [Sport]
    var createdBy: String
}
