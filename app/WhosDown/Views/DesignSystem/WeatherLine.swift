import SwiftUI

/// The weather line on H09, H14, H18, H19 (1.9). Indoor Matches say "Indoor"; otherwise the forecast
/// for the start hour, or nothing at all when there isn't one (rule 6: never an error).
struct WeatherLine: View {
    let location: Coordinate
    let date: Date
    let isIndoor: Bool

    @Environment(AppEnvironment.self) private var environment
    @State private var summary: WeatherSummary?

    var body: some View {
        Group {
            if isIndoor {
                Label("Indoor", systemImage: "building.2")
            } else if let summary {
                Label("\(summary.line) · Outdoor", systemImage: "cloud.sun")
            }
        }
        .font(.subheadline)
        .foregroundStyle(Color.textSecondary)
        .task(id: "\(location.latitude),\(location.longitude),\(date.timeIntervalSince1970),\(isIndoor)") {
            summary = isIndoor ? nil : await environment.weather.forecast(at: location, for: date)
        }
    }
}
