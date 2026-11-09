import FirebaseFirestore
import Foundation

/// What a Host fills in to save a new Venue (1.12 rule 3).
nonisolated struct VenueDraft: Equatable, Sendable {
    var name: String
    var address: String
    var location: Coordinate
    var isIndoor: Bool
    var surface: Surface
    var hasLights: Bool
}

/// Playing surfaces offered for a new Venue (1.12 rule 3).
nonisolated enum Surface: String, CaseIterable, Identifiable, Sendable {
    case turf, grass, hardwood, court, sand, other
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// R11 and W18: `venues/{venueId}`.
protocol VenueRepository {
    func venue(id: String) async throws -> Venue?
    /// Saved Venues within `radiusMeters` of the center, nearest first (geohash ranges, then exact distance).
    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Venue]
    /// Saved Venues whose name starts with the text (case-insensitive), up to 10.
    func search(namePrefix: String) async throws -> [Venue]
    /// W18: saves a new Venue created by this Player and returns it with its ID.
    func create(_ draft: VenueDraft, createdBy userId: String) async throws -> Venue
}

final class FirebaseVenueRepository: VenueRepository {
    private let db = Firestore.firestore()

    func venue(id: String) async throws -> Venue? {
        let snapshot = try await db.document("venues/\(id)").getDocument()
        return snapshot.exists ? try snapshot.decoded(as: Venue.self) : nil
    }

    func nearby(center: Coordinate, radiusMeters: Double) async throws -> [Venue] {
        let bounds = Geohash.queryBounds(latitude: center.latitude, longitude: center.longitude, radius: radiusMeters)
        var venues: [String: Venue] = [:]
        for bound in bounds {
            let snapshot = try await db.collection("venues")
                .order(by: "geohash")
                .start(at: [bound.start])
                .end(at: [bound.end])
                .getDocuments()
            for document in snapshot.documents {
                let venue = try document.decoded(as: Venue.self)
                if let id = venue.id { venues[id] = venue }
            }
        }
        return VenueRules.sortedByDistance(Array(venues.values), from: center, within: radiusMeters)
    }

    func search(namePrefix: String) async throws -> [Venue] {
        let prefix = namePrefix.trimmingCharacters(in: .whitespaces).lowercased()
        guard !prefix.isEmpty else { return [] }
        let snapshot = try await db.collection("venues")
            .order(by: "nameLowercase")
            .start(at: [prefix])
            .end(at: [prefix + "\u{f8ff}"])
            .limit(to: 10)
            .getDocuments()
        return try snapshot.documents.map { try $0.decoded(as: Venue.self) }
    }

    func create(_ draft: VenueDraft, createdBy userId: String) async throws -> Venue {
        let reference = db.collection("venues").document()
        let venue = Venue(
            id: reference.documentID,
            name: draft.name,
            nameLowercase: draft.name.lowercased(),
            address: draft.address,
            location: draft.location,
            geohash: Geohash.encode(latitude: draft.location.latitude, longitude: draft.location.longitude),
            isIndoor: draft.isIndoor,
            surface: draft.surface.rawValue,
            hasLights: draft.hasLights,
            sports: [],
            createdBy: userId
        )
        try await reference.setData([
            "name": venue.name,
            "nameLowercase": venue.nameLowercase,
            "address": venue.address,
            "location": ["latitude": venue.location.latitude, "longitude": venue.location.longitude],
            "geohash": venue.geohash,
            "isIndoor": venue.isIndoor,
            "surface": venue.surface,
            "hasLights": venue.hasLights,
            "sports": [String](),
            "createdBy": userId,
        ])
        return venue
    }
}
