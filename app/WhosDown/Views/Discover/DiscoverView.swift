import SwiftUI

/// Phase 0 placeholder for the Discover tab: a plain list of upcoming Matches from the emulator.
/// 1.5 (map) and 1.6 (list) replace this screen.
struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: DiscoverViewModel?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel?.state ?? .loading {
                case .loading:
                    ProgressView()
                case .loaded(let matches) where matches.isEmpty:
                    ContentUnavailableView("No Matches nearby yet", systemImage: "sportscourt")
                case .loaded(let matches):
                    List(matches) { match in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(match.title).font(.headline)
                            Text("\(match.startTime.formatted(date: .abbreviated, time: .shortened)) · \(match.venueName)")
                                .font(.subheadline).foregroundStyle(Color.textSecondary)
                            HStack {
                                Chip(text: match.skillLevel.displayName)
                                Chip(text: "\(match.joinedCount)/\(match.playerLimit)", foreground: .info, background: .info.opacity(0.1))
                            }
                        }
                    }
                case .failed(let message):
                    ContentUnavailableView("Something went wrong", systemImage: "wifi.exclamationmark", description: Text(message))
                }
            }
            .navigationTitle("WhosDown")
            .refreshable { await viewModel?.load() }
        }
        .task {
            if viewModel == nil { viewModel = DiscoverViewModel(matches: environment.matches) }
            await viewModel?.load()
        }
    }
}

#Preview {
    DiscoverView().environment(AppEnvironment.preview())
}
