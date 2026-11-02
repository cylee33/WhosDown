import Foundation

/// Geohash encoding and radius-query ranges, ported from Firebase's `geofire-common` 6.0.0
/// (`firebase/node_modules/geofire-common`). We don't use GeoFireUtils because it doesn't
/// support Firebase 13 (D50). `GeohashTests` check every function against that library's output.
nonisolated enum Geohash {
    static let defaultPrecision = 10
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    private static let earthMeridionalCircumference = 40_007_860.0
    private static let metersPerDegreeLatitude = 110_574.0
    private static let bitsPerChar = 5
    private static let maximumBitsPrecision = 22 * bitsPerChar
    private static let earthEquatorialRadius = 6_378_137.0
    private static let e2 = 0.00669447819799
    private static let epsilon = 1e-12

    /// The geohash of a point, e.g. "dppnhf…" around CMU.
    static func encode(latitude: Double, longitude: Double, precision: Int = defaultPrecision) -> String {
        var latitudeRange = (min: -90.0, max: 90.0)
        var longitudeRange = (min: -180.0, max: 180.0)
        var hash = ""
        var hashValue = 0
        var bits = 0
        var even = true
        while hash.count < precision {
            let value = even ? longitude : latitude
            let mid = even ? (longitudeRange.min + longitudeRange.max) / 2 : (latitudeRange.min + latitudeRange.max) / 2
            if value > mid {
                hashValue = (hashValue << 1) + 1
                if even { longitudeRange.min = mid } else { latitudeRange.min = mid }
            } else {
                hashValue <<= 1
                if even { longitudeRange.max = mid } else { latitudeRange.max = mid }
            }
            even.toggle()
            if bits < 4 {
                bits += 1
            } else {
                bits = 0
                hash.append(base32[hashValue])
                hashValue = 0
            }
        }
        return hash
    }

    /// `[start, end]` ranges that together cover every geohash within `radius` meters of the center.
    /// Query `geohash >= start AND geohash <= end` for each, then drop results outside the exact distance.
    static func queryBounds(latitude: Double, longitude: Double, radius: Double) -> [(start: String, end: String)] {
        let queryBits = max(1, boundingBoxBits(latitude: latitude, size: radius))
        let precision = Int((Double(queryBits) / Double(bitsPerChar)).rounded(.up))
        let queries = boundingBoxCoordinates(latitude: latitude, longitude: longitude, radius: radius).map { point in
            query(encode(latitude: point.latitude, longitude: point.longitude, precision: precision), bits: queryBits)
        }
        var unique: [(start: String, end: String)] = []
        for query in queries where !unique.contains(where: { $0 == query }) {
            unique.append(query)
        }
        return unique
    }

    /// Great-circle distance in meters (haversine, as `geofire-common`'s `distanceBetween`, times 1000).
    static func distance(fromLatitude lat1: Double, longitude lon1: Double, toLatitude lat2: Double, longitude lon2: Double) -> Double {
        let radius = 6371.0
        let latDelta = radians(lat2 - lat1)
        let lonDelta = radians(lon2 - lon1)
        let a = sin(latDelta / 2) * sin(latDelta / 2)
            + cos(radians(lat1)) * cos(radians(lat2)) * sin(lonDelta / 2) * sin(lonDelta / 2)
        return radius * 2 * atan2(sqrt(a), sqrt(1 - a)) * 1000
    }

    // MARK: - Internals (names follow geofire-common)

    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }

    static func metersToLongitudeDegrees(_ distance: Double, latitude: Double) -> Double {
        let r = radians(latitude)
        let num = cos(r) * earthEquatorialRadius * .pi / 180
        let denom = 1 / sqrt(1 - e2 * sin(r) * sin(r))
        let deltaDeg = num * denom
        if deltaDeg < epsilon { return distance > 0 ? 360 : 0 }
        return min(360, distance / deltaDeg)
    }

    private static func longitudeBitsForResolution(_ resolution: Double, latitude: Double) -> Double {
        let degs = metersToLongitudeDegrees(resolution, latitude: latitude)
        return abs(degs) > 0.000001 ? max(1, log2(360 / degs)) : 1
    }

    private static func latitudeBitsForResolution(_ resolution: Double) -> Double {
        min(log2(earthMeridionalCircumference / 2 / resolution), Double(maximumBitsPrecision))
    }

    static func wrapLongitude(_ longitude: Double) -> Double {
        if longitude <= 180 && longitude >= -180 { return longitude }
        let adjusted = longitude + 180
        if adjusted > 0 { return adjusted.truncatingRemainder(dividingBy: 360) - 180 }
        return 180 - (-adjusted).truncatingRemainder(dividingBy: 360)
    }

    static func boundingBoxBits(latitude: Double, size: Double) -> Int {
        let latDelta = size / metersPerDegreeLatitude
        let north = min(90, latitude + latDelta)
        let south = max(-90, latitude - latDelta)
        let bitsLat = Int(floor(latitudeBitsForResolution(size))) * 2
        let bitsLongNorth = Int(floor(longitudeBitsForResolution(size, latitude: north))) * 2 - 1
        let bitsLongSouth = Int(floor(longitudeBitsForResolution(size, latitude: south))) * 2 - 1
        return min(bitsLat, bitsLongNorth, bitsLongSouth, maximumBitsPrecision)
    }

    private static func boundingBoxCoordinates(latitude: Double, longitude: Double, radius: Double) -> [(latitude: Double, longitude: Double)] {
        let latDegrees = radius / metersPerDegreeLatitude
        let north = min(90, latitude + latDegrees)
        let south = max(-90, latitude - latDegrees)
        let longDegs = max(metersToLongitudeDegrees(radius, latitude: north), metersToLongitudeDegrees(radius, latitude: south))
        return [
            (latitude, longitude),
            (latitude, wrapLongitude(longitude - longDegs)),
            (latitude, wrapLongitude(longitude + longDegs)),
            (north, longitude),
            (north, wrapLongitude(longitude - longDegs)),
            (north, wrapLongitude(longitude + longDegs)),
            (south, longitude),
            (south, wrapLongitude(longitude - longDegs)),
            (south, wrapLongitude(longitude + longDegs)),
        ]
    }

    static func query(_ geohash: String, bits: Int) -> (start: String, end: String) {
        let precision = Int((Double(bits) / Double(bitsPerChar)).rounded(.up))
        if geohash.count < precision { return (geohash, geohash + "~") }
        let trimmed = String(geohash.prefix(precision))
        let base = String(trimmed.dropLast())
        let lastValue = base32.firstIndex(of: trimmed.last!)!
        let significantBits = bits - base.count * bitsPerChar
        let unusedBits = bitsPerChar - significantBits
        let startValue = (lastValue >> unusedBits) << unusedBits
        let endValue = startValue + (1 << unusedBits)
        if endValue > 31 { return (base + String(base32[startValue]), base + "~") }
        return (base + String(base32[startValue]), base + String(base32[endValue]))
    }
}
