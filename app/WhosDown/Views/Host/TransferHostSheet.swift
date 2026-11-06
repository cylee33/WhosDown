import SwiftUI

/// H22 Transfer host (1.28).
struct TransferHostSheet: View {
    let match: Match

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var players: [RSVP] = []
    @State private var selected: String?
    @State private var reliability: [String: String] = [:]
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Transfer host").font(.title2.bold())
            Text("Choose a joined Player to become Host.").foregroundStyle(Color.textSecondary)
            if players.isEmpty {
                Text("No Players to transfer to yet. You can cancel the Match instead.")
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            ForEach(players) { player in
                Button { selected = player.userId } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(player.displayName).foregroundStyle(Color.textPrimary)
                            Text(reliability[player.userId] ?? "New player").font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: selected == player.userId ? "largecircle.fill.circle" : "circle")
                    }
                }
                .buttonStyle(.plain)
            }
            if let selected, let name = players.first(where: { $0.userId == selected })?.displayName {
                Text("\(name) will gain edit, approval, chat, and cancellation controls.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
            }
            if let message { Text(message).font(.footnote).foregroundStyle(Color.destructive) }
            Button("Transfer host") { Task { await transfer() } }
                .buttonStyle(.primary)
                .disabled(selected == nil)
        }
        .padding(Spacing.m)
        .navigationTitle("Transfer host")
        .task {
            let roster = (try? await environment.rsvps.approvedOnce(matchId: match.id ?? "")) ?? []
            players = roster.filter { !$0.isHost }
            for player in players {
                reliability[player.userId] = (try? await environment.reliability.reliability(userId: player.userId))?.label
            }
        }
    }

    private func transfer() async {
        guard let hostId = session.user?.id, let player = players.first(where: { $0.userId == selected }) else { return }
        do {
            try await environment.matches.transferHost(match, to: player, hostId: hostId)
            dismiss()
        } catch {
            message = "Couldn't transfer this Match."
        }
    }
}
