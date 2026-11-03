import Foundation

/// The forecast for one hour, as shown in one line on H09, H14, H18, H19 (1.9).
nonisolated struct WeatherSummary: Equatable, Sendable {
    var temperatureF: Int
    var condition: String
    /// Chance of rain in percent, shown only from 10% (rule 4).
    var rainChance: Int?

    /// "64°F · Clear · 8% rain" style, without the rain part under 10%.
    var line: String {
        var parts = ["\(temperatureF)°F", condition]
        if let rainChance, rainChance >= 10 { parts.append("\(rainChance)% rain") }
        return parts.joined(separator: " · ")
    }
}

/// Weather for outdoor Matches (1.9). Returns nil when there's nothing worth showing: indoor, too far ahead,
/// already over, or the forecast couldn't be loaded. Weather never shows an error (rule 6).
protocol WeatherService {
    func forecast(at location: Coordinate, for date: Date) async -> WeatherSummary?
}

/// Open-Meteo, free and keyless. One request per location per 30 minutes (rule 5).
final class OpenMeteoWeatherService: WeatherService {
    static let forecastDays = 16
    private var cache: [String: (fetched: Date, hours: [OpenMeteoForecast.Hour])] = [:]
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func forecast(at location: Coordinate, for date: Date) async -> WeatherSummary? {
        let now = Date.now
        guard date > now.addingTimeInterval(-3600),
              date < now.addingTimeInterval(TimeInterval(Self.forecastDays) * 86400) else { return nil }
        let key = String(format: "%.2f,%.2f", location.latitude, location.longitude)
        var hours = cache[key].flatMap { now.timeIntervalSince($0.fetched) < 1800 ? $0.hours : nil }
        if hours == nil {
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: String(format: "%.2f", location.latitude)),
                URLQueryItem(name: "longitude", value: String(format: "%.2f", location.longitude)),
                URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,precipitation_probability"),
                URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "forecast_days", value: String(Self.forecastDays)),
            ]
            guard let (data, _) = try? await session.data(from: components.url!),
                  let parsed = try? OpenMeteoForecast.hours(from: data) else { return nil }
            cache[key] = (now, parsed)
            hours = parsed
        }
        return OpenMeteoForecast.summary(closestTo: date, in: hours ?? [])
    }
}

/// Parsing for Open-Meteo responses, kept separate so it can be tested with saved JSON.
nonisolated enum OpenMeteoForecast {
    struct Hour: Equatable, Sendable {
        var time: Date
        var temperatureF: Double
        var weatherCode: Int
        var precipitationProbability: Int?
    }

    private struct Response: Decodable {
        var utc_offset_seconds: Int
        var hourly: Hourly
        struct Hourly: Decodable {
            var time: [String]
            var temperature_2m: [Double?]
            var weather_code: [Int?]
            var precipitation_probability: [Int?]
        }
    }

    /// The hourly times are local to the place with no zone, so they're read as UTC and then shifted
    /// back by `utc_offset_seconds` (lessons-learned 2026-11-01).
    static func hours(from data: Data) throws -> [Hour] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let hourly = response.hourly
        return hourly.time.indices.compactMap { index in
            guard let local = formatter.date(from: hourly.time[index]),
                  let temperature = hourly.temperature_2m[safe: index] ?? nil,
                  let code = hourly.weather_code[safe: index] ?? nil else { return nil }
            return Hour(
                time: local.addingTimeInterval(TimeInterval(-response.utc_offset_seconds)),
                temperatureF: temperature,
                weatherCode: code,
                precipitationProbability: hourly.precipitation_probability[safe: index] ?? nil
            )
        }
    }

    /// The forecast hour closest to the Match's start (rule 2).
    static func summary(closestTo date: Date, in hours: [Hour]) -> WeatherSummary? {
        guard let hour = hours.min(by: { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) }),
              abs(hour.time.timeIntervalSince(date)) <= 3600 else { return nil }
        return WeatherSummary(
            temperatureF: Int(hour.temperatureF.rounded()),
            condition: condition(forWMOCode: hour.weatherCode),
            rainChance: hour.precipitationProbability
        )
    }

    /// WMO weather codes grouped into the words on H09 (rule 4).
    static func condition(forWMOCode code: Int) -> String {
        switch code {
        case 0: "Clear"
        case 1, 2: "Partly cloudy"
        case 3: "Cloudy"
        case 45, 48: "Fog"
        case 51...57: "Drizzle"
        case 61...67, 80...82: "Rain"
        case 71...77, 85, 86: "Snow"
        case 95...99: "Thunderstorm"
        default: "Cloudy"
        }
    }
}

private nonisolated extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
