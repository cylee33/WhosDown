import CoreLocation
import Foundation
import MapKit

/// Apple Maps place search for H40 (1.12).
protocol PlaceSearchService {
    /// Places matching the text near the center (about 10 miles around it).
    func search(_ text: String, near center: Coordinate) async throws -> [Place]
}

final class MapKitPlaceSearchService: PlaceSearchService {
    func search(_ text: String, near center: Coordinate) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            latitudinalMeters: 16_000,
            longitudinalMeters: 16_000
        )
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { item in
            guard let name = item.name else { return nil }
            let coordinate = item.location.coordinate
            return Place(
                name: name,
                address: item.address?.shortAddress ?? item.address?.fullAddress ?? "",
                location: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
        }
    }
}

/// The Player's current location, once (1.12 centers H40 on it; 1.5 will reuse it).
protocol LocationService {
    /// Nil when location isn't allowed or can't be found quickly.
    func currentLocation() async -> Coordinate?
}

final class SystemLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Coordinate?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async -> Coordinate? {
        guard [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation?.resume(returning: nil)
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last.map { Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        Task { @MainActor in self.finish(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }

    private func finish(_ coordinate: Coordinate?) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }
}
