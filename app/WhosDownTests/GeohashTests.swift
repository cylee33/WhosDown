import Foundation
import Testing
@testable import WhosDown

/// Expected values were produced by Firebase's `geofire-common` 6.0.0 (node, 2026-11-02),
/// so these tests prove the Swift port gives the same answers (D50).
struct GeohashTests {
    @Test(arguments: [
        (40.4433, -79.9436, "dppnhf6z71"),
        (40.4364, -79.9454, "dppnhc1x15"),
        (0.0, 0.0, "7zzzzzzzzz"),
        (-33.8688, 151.2093, "r3gx2f77bn"),
        (89.9, 179.9, "zzzzmtz1my"),
        (51.5, -0.12, "gcpuvr295z"),
    ])
    func encodeMatchesGeofireCommon(latitude: Double, longitude: Double, expected: String) {
        #expect(Geohash.encode(latitude: latitude, longitude: longitude) == expected)
        #expect(Geohash.encode(latitude: latitude, longitude: longitude, precision: 5) == String(expected.prefix(5)))
    }

    @Test func queryBoundsMatchGeofireCommon() {
        func bounds(_ lat: Double, _ lon: Double, _ radius: Double) -> [[String]] {
            Geohash.queryBounds(latitude: lat, longitude: lon, radius: radius).map { [$0.start, $0.end] }
        }
        // 5 miles around CMU (the Discover default radius).
        #expect(bounds(40.4433, -79.9436, 8046.72) == [["dppnh", "dppn~"], ["dppn0", "dppnh"], ["dppjh", "dppj~"], ["dppj0", "dppjh"]])
        #expect(bounds(40.4433, -79.9436, 500) == [["dppnhf", "dppnhh"], ["dppnhd", "dppnhf"], ["dppnhb", "dppnhd"], ["dppnh8", "dppnhb"]])
        // Across the date line.
        #expect(bounds(0, 179.99, 10000) == [["rzzz", "rzz~"], ["2pbp", "2pbq"], ["xbpb", "xbpc"], ["8000", "8001"]])
        #expect(bounds(-33.8688, 151.2093, 50000) == [["r3gh", "r3g~"], ["r650", "r65h"]])
    }

    @Test func distanceMatchesGeofireCommon() {
        let cmuToSchenley = Geohash.distance(fromLatitude: 40.4433, longitude: -79.9436, toLatitude: 40.4364, longitude: -79.9454)
        #expect(abs(cmuToSchenley - 782.2212014644924) < 0.001)
        let longWay = Geohash.distance(fromLatitude: 0, longitude: 0, toLatitude: 51.5, longitude: -0.12)
        #expect(abs(longWay - 5_726_549.836941572) < 0.01)
    }

    @Test func seededGeohashesMatchTheSeedScript() {
        // firebase/seed/seed.js stores geohashForLocation([40.4433, -79.9436]) for CMU Soccer Field.
        #expect(Geohash.encode(latitude: 40.4433, longitude: -79.9436).hasPrefix("dppnhf"))
    }
}
