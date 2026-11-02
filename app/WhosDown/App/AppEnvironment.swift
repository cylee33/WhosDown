import SwiftUI

/// The one dependency container (ADR-0001, 1.1 rule 4). Views get it from the SwiftUI environment
/// and hand repositories to their view models. Features add their repositories here.
@Observable
final class AppEnvironment {
    let auth: AuthRepository
    let users: UserRepository
    let matches: MatchRepository
    let permissions: PermissionsService
    let reliability: ReliabilityRepository
    let venues: VenueRepository
    let placeSearch: PlaceSearchService
    let location: LocationService

    init(
        auth: AuthRepository, users: UserRepository, matches: MatchRepository,
        permissions: PermissionsService, reliability: ReliabilityRepository,
        venues: VenueRepository, placeSearch: PlaceSearchService, location: LocationService
    ) {
        self.auth = auth
        self.users = users
        self.matches = matches
        self.permissions = permissions
        self.reliability = reliability
        self.venues = venues
        self.placeSearch = placeSearch
        self.location = location
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            auth: FirebaseAuthRepository(), users: FirebaseUserRepository(),
            matches: FirebaseMatchRepository(), permissions: SystemPermissionsService(),
            reliability: FirebaseReliabilityRepository(), venues: FirebaseVenueRepository(),
            placeSearch: MapKitPlaceSearchService(), location: SystemLocationService()
        )
    }

    static func preview(signedInAs userId: String? = "seed_alex") -> AppEnvironment {
        AppEnvironment(
            auth: FakeAuthRepository(signedInAs: userId), users: FakeUserRepository(),
            matches: FakeMatchRepository(), permissions: FakePermissionsService(),
            reliability: FakeReliabilityRepository(), venues: FakeVenueRepository(),
            placeSearch: FakePlaceSearchService(), location: FakeLocationService()
        )
    }
}
