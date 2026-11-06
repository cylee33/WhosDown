import SwiftUI

/// H20 Manage Match (1.15). Edit, transfer, check-in, and cancel are wired in Phase 6.
struct HostDashboardView: View {
    let matchId: String

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: HostDashboardViewModel?

    var body: some View {
        Group {
            if let viewModel, let match = viewModel.match {
                dashboard(match, viewModel)
            } else {
                ProgressView()
            }
        }
        .background(Color.background)
        .navigationTitle("Manage Match")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let hostId = session.user?.id else { return }
            let viewModel = HostDashboardViewModel(
                matchId: matchId, hostId: hostId, matches: environment.matches, rsvps: environment.rsvps,
                reliability: environment.reliability, chat: environment.chat
            )
            self.viewModel = viewModel
            await viewModel.start()
        }
    }

    private func dashboard(_ match: Match, _ viewModel: HostDashboardViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(match.title).font(.title2.bold()).foregroundStyle(Color.textPrimary)
                    Text("\(MatchFormatting.when(match)) · \(match.venueName)")
                        .foregroundStyle(Color.textSecondary)
                    Text("\(match.joinedCount) / \(match.playerLimit) joined · \(viewModel.requests.count) requests")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.textPrimary)
                }
                .card()

                NavigationLink {
                    JoinRequestsView(viewModel: viewModel)
                } label: {
                    row(title: "Join requests", detail: viewModel.requests.isEmpty ? "No requests" : "\(viewModel.requests.count) waiting")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MatchChatView(
                        matchId: match.id ?? matchId, title: match.title, hostId: match.hostId, playerCount: match.joinedCount
                    )
                } label: {
                    row(title: "Match chat", detail: viewModel.lastMessage ?? "No messages yet")
                }
                .buttonStyle(.plain)
                NavigationLink { EditMatchView(match: match) } label: { row(title: "Edit Match", detail: "Time, place, limit") }
                    .buttonStyle(.plain)
                NavigationLink { TransferHostSheet(match: match) } label: { row(title: "Transfer host", detail: "Can't attend?") }
                    .buttonStyle(.plain)
                if CheckInRules.isOpen(match) {
                    NavigationLink { CheckInView(match: match) } label: { row(title: "Check in players", detail: "Record who came") }
                        .buttonStyle(.plain)
                }

                Text("Ownership safeguard: you can't leave a Match you host. Cancel it, or transfer the Host role.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
                NavigationLink { CancelMatchSheet(match: match) } label: {
                    Text("Cancel Match").font(.headline).foregroundStyle(Color.destructive)
                }
            }
            .padding(Spacing.m)
        }
    }

    private func row(title: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                Text(detail).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
        }
        .card()
    }
}
