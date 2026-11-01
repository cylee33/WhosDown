import Foundation

// Open-Meteo forecast structs. Same code as WhosDownWeather.playground.

// MARK: - Decodable structs for the Open-Meteo response

struct ForecastResponse: Decodable {
  let latitude: Double
  let longitude: Double
  let timezone: String
  let utcOffsetSeconds: Int
  let hourlyUnits: HourlyUnits
  let hourly: Hourly

  enum CodingKeys: String, CodingKey {
    case latitude, longitude, timezone
    case utcOffsetSeconds = "utc_offset_seconds"
    case hourlyUnits = "hourly_units"
    case hourly
  }
}

struct HourlyUnits: Decodable {
  let temperature: String
  let windSpeed: String

  enum CodingKeys: String, CodingKey {
    case temperature = "temperature_2m"
    case windSpeed = "wind_speed_10m"
  }
}

// Open-Meteo returns parallel arrays: index i of every array is the same hour.
struct Hourly: Decodable {
  let time: [String]
  let temperature: [Double]
  let precipitationProbability: [Int]
  let weatherCode: [Int]
  let windSpeed: [Double]

  enum CodingKeys: String, CodingKey {
    case time
    case temperature = "temperature_2m"
    case precipitationProbability = "precipitation_probability"
    case weatherCode = "weather_code"
    case windSpeed = "wind_speed_10m"
  }
}

// MARK: - App-side struct the interface reads

struct HourlyForecast {
  let date: Date
  let temperatureF: Double
  let precipitationProbability: Int
  let weatherCode: Int
  let windSpeedMph: Double

  // WMO weather codes used by Open-Meteo
  var conditionText: String {
    switch weatherCode {
    case 0: return "Clear"
    case 1: return "Mostly clear"
    case 2: return "Partly cloudy"
    case 3: return "Overcast"
    case 45, 48: return "Fog"
    case 51, 53, 55, 56, 57: return "Drizzle"
    case 61, 63, 65, 66, 67: return "Rain"
    case 71, 73, 75, 77: return "Snow"
    case 80, 81, 82: return "Rain showers"
    case 85, 86: return "Snow showers"
    case 95, 96, 99: return "Thunderstorm"
    default: return "Unknown"
    }
  }

  // Line shown on H09 / H14 / H18, e.g. "64°F · Clear · 8% rain"
  var summaryLine: String {
    "\(Int(temperatureF.rounded()))°F · \(conditionText) · \(precipitationProbability)% rain"
  }
}

extension ForecastResponse {
  // Turns the parallel arrays into one HourlyForecast per hour.
  // Times come back in local time without an offset, so the response's
  // utc_offset_seconds is applied when parsing.
  var hours: [HourlyForecast] {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
    formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds)

    return hourly.time.indices.compactMap { i in
      guard let date = formatter.date(from: hourly.time[i]) else { return nil }
      return HourlyForecast(
        date: date,
        temperatureF: hourly.temperature[i],
        precipitationProbability: hourly.precipitationProbability[i],
        weatherCode: hourly.weatherCode[i],
        windSpeedMph: hourly.windSpeed[i]
      )
    }
  }

  // The hour closest to a game's start time.
  func forecast(closestTo date: Date) -> HourlyForecast? {
    hours.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
  }
}

// MARK: - Request

func fetchForecast(latitude: Double, longitude: Double) async throws -> ForecastResponse {
  var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
  components.queryItems = [
    URLQueryItem(name: "latitude", value: String(latitude)),
    URLQueryItem(name: "longitude", value: String(longitude)),
    URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code,wind_speed_10m"),
    URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
    URLQueryItem(name: "wind_speed_unit", value: "mph"),
    URLQueryItem(name: "timezone", value: "America/New_York"),
    URLQueryItem(name: "forecast_days", value: "7")
  ]
  let (data, response) = try await URLSession.shared.data(from: components.url!)
  if let http = response as? HTTPURLResponse, http.statusCode != 200 {
    throw URLError(.badServerResponse)
  }
  return try JSONDecoder().decode(ForecastResponse.self, from: data)
}

