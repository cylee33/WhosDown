import SwiftUI

/// H27 My Matches (1.19).
struct MyMatchesView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: MyMatchesViewModel?
    @State private var path: [String] = []
    @State private var managing: HostRoute?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .background(Color.background)
            .navigationTitle("My Matches")
            .navigationDestination(for: String.self) { id in
                MatchDetailView(matchId: id)
            }
            .navigationDestination(item: $managing) { route in
                HostDashboardView(matchId: route.matchId)
            }
        }
        .task(id: session.user?.id) {
            guard let userId = session.user?.id else { return }
            let viewModel = MyMatchesViewModel(userId: userId, matches: environment.matches, rsvps: environment.rsvps)
            self.viewModel = viewModel
            await viewModel.start()
        }
    }

    private func content(_ viewModel: MyMatchesViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: Spacing.s) {
            Picker("Matches", selection: $viewModel.segment) {
                ForEach(MyMatchesViewModel.Segment.allCases) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    switch viewModel.segment {
                    case .upcoming:
                        if viewModel.upcoming.isEmpty {
                            ContentUnavailableView("No upcoming Matches", systemImage: "map", description: Text("Find one on Discover."))
                        }
                        ForEach(viewModel.upcoming) { entry in
                            Button { path.append(entry.id) } label: {
                                MatchListCard(match: entry.match, badge: badge(for: entry))
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Matches move to Past after they end.")
                            .font(.footnote).foregroundStyle(Color.textSecondary)
                    case .hosting:
                        if viewModel.hosting.isEmpty {
                            ContentUnavailableView("You're not hosting anything", systemImage: "plus.circle", description: Text("Create a Match."))
                        }
                        ForEach(viewModel.hosting) { match in
                            Button { if let id = match.id { managing = HostRoute(matchId: id) } } label: {
                                MatchListCard(match: match, badge: "HOSTING")
                            }
                            .buttonStyle(.plain)
                        }
                    case .past:
                        PastMatchesView(months: viewModel.past) { path.append($0.id ?? "") }
                    }
                    if let message = viewModel.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                }
                .padding(Spacing.m)
            }
            .refreshable { await viewModel.load() }
        }
    }

    private func badge(for entry: MatchEntry) -> String {
        switch entry.rsvp?.status {
        case .approved: "APPROVED"
        case .pending: "PENDING"
        case .declined: "DECLINED"
        case .waitlisted:
            if let position = MyMatchesSorter.waitlistPosition(userId: entry.rsvp?.userId ?? "", match: entry.match) {
                "WAITLIST #\(position)"
            } else {
                "WAITLIST"
            }
        default: ""
        }
    }
}

struct HostRoute: Hashable, Identifiable {
    let matchId: String
    var id: String { matchId }
}
