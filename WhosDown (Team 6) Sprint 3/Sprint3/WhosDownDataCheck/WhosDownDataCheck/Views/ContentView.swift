import SwiftUI
import FirebaseFirestore

struct ContentView: View {
  // Launch with `-tab models` or `-tab firestore` to open a tab directly.
  @State private var tab = UserDefaults.standard.string(forKey: "tab") ?? "weather"

  var body: some View {
    TabView(selection: $tab) {
      WeatherView()
        .tabItem { Label("Weather", systemImage: "cloud.sun") }
        .tag("weather")
      ModelCheckView()
        .tabItem { Label("Models", systemImage: "checkmark.seal") }
        .tag("models")
      FirestoreView()
        .tabItem { Label("Firestore", systemImage: "flame") }
        .tag("firestore")
    }
  }
}

// MARK: - Weather (Open-Meteo)

struct WeatherRow: Identifiable {
  let id = UUID()
  let game: Game
  let forecast: HourlyForecast?
  let error: String?
}

struct WeatherView: View {
  @State private var rows: [WeatherRow] = []
  @State private var loading = false

  private var games: [Game] {
    SeedData.documents
      .filter { $0.path.hasPrefix("games/") && $0.path.split(separator: "/").count == 2 }
      .compactMap { try? decode(Game.self, $0.data, SeedData.offlineDB.document($0.path)) }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          Text("GET api.open-meteo.com/v1/forecast for each game's GeoPoint, decoded into ForecastResponse, then the hour closest to startTime.")
            .font(.footnote).foregroundStyle(.secondary)
        }
        ForEach(rows) { row in
          Section(row.game.title) {
            LabeledContent("Venue", value: row.game.venueName)
            LabeledContent("Start", value: row.game.startTime.formatted(date: .abbreviated, time: .shortened))
            if let f = row.forecast {
              LabeledContent("Forecast hour", value: f.date.formatted(date: .omitted, time: .shortened))
              Text("\(f.summaryLine) · \(row.game.isIndoor ? "Indoor" : "Outdoor")").font(.headline)
              LabeledContent("Wind", value: "\(Int(f.windSpeedMph.rounded())) mph")
            } else if let error = row.error {
              Text(error).foregroundStyle(.red)
            }
          }
        }
      }
      .overlay { if loading { ProgressView() } }
      .navigationTitle("Open-Meteo")
      .refreshable { await load() }
      .task { await load() }
    }
  }

  private func load() async {
    loading = true
    var result: [WeatherRow] = []
    for game in games {
      do {
        let response = try await fetchForecast(latitude: game.location.latitude, longitude: game.location.longitude)
        result.append(WeatherRow(game: game, forecast: response.forecast(closestTo: game.startTime), error: nil))
      } catch {
        result.append(WeatherRow(game: game, forecast: nil, error: error.localizedDescription))
      }
    }
    rows = result
    loading = false
  }
}

// MARK: - Models (offline decode of every seed document)

struct ModelCheckView: View {
  private let results: [(path: String, line: String, ok: Bool)] = SeedData.documents.map { doc in
    do { return (doc.path, try doc.runCheck(), true) }
    catch { return (doc.path, "\(error)", false) }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          let passed = results.filter(\.ok).count
          Label("\(passed) / \(results.count) documents decoded", systemImage: passed == results.count ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(passed == results.count ? .green : .red)
          Text("Each seed document (with Firestore Timestamp and GeoPoint values) decoded into its Swift struct with Firestore.Decoder.")
            .font(.footnote).foregroundStyle(.secondary)
        }
        ForEach(results, id: \.path) { r in
          VStack(alignment: .leading, spacing: 2) {
            Text(r.path).font(.caption.monospaced()).foregroundStyle(.secondary)
            Label(r.line, systemImage: r.ok ? "checkmark" : "xmark")
              .font(.subheadline)
              .foregroundStyle(r.ok ? Color.primary : Color.red)
          }
        }
      }
      .navigationTitle("Struct decoding")
    }
  }
}

// MARK: - Firestore (seed + read back)

struct FirestoreView: View {
  @State private var results: [CollectionResult] = []
  @State private var status = ""
  @State private var busy = false

  var body: some View {
    NavigationStack {
      List {
        if !FirestoreService.isConfigured {
          Text("Add GoogleService-Info.plist to the WhosDownDataCheck folder, then rebuild.")
            .foregroundStyle(.secondary)
        } else {
          Section {
            Button("Seed sample data") { Task { await seed() } }
            Button("Load from Firestore") { Task { await load() } }
            if !status.isEmpty { Text(status).font(.footnote) }
          }
          ForEach(results) { r in
            Section("\(r.path) (\(r.rows.count))") {
              if let error = r.error {
                Text(error).foregroundStyle(.red)
              }
              ForEach(r.rows, id: \.self) { Text($0).font(.subheadline) }
            }
          }
        }
      }
      .overlay { if busy { ProgressView() } }
      .navigationTitle("Firestore")
      .task {
        if FirestoreService.isConfigured, UserDefaults.standard.bool(forKey: "autoload") {
          await load()
        }
      }
    }
  }

  private func seed() async {
    busy = true
    do {
      try await FirestoreService.seed()
      status = "Wrote \(SeedData.documents.count) documents."
    } catch {
      status = "Seed failed: \(error.localizedDescription)"
    }
    busy = false
    await load()
  }

  private func load() async {
    busy = true
    results = await FirestoreService.loadAll()
    let total = results.reduce(0) { $0 + $1.rows.count }
    status = "Read \(total) documents from \(results.count) collections."
    busy = false
  }
}
