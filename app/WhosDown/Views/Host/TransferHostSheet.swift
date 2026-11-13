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
    @State private var isWorking = false

    var body: some View {
        SheetContainer(
            title: "Transfer host", message: "Choose a joined Player to become Host.",
            primaryTitle: isWorking ? "Transferring…" : "Transfer host", primaryEnabled: selected != nil,
            primaryAction: { Task { await transfer() } }, secondaryTitle: "Keep hosting", secondaryAction: { dismiss() }
        ) {
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
                    // Without this, taps on the empty middle of the row (the Spacer) do nothing.
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let selected, let name = players.first(where: { $0.userId == selected })?.displayName {
                Text("\(name) will gain edit, approval, chat, and cancellation controls.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
            }
            if let message { Text(message).font(.footnote).foregroundStyle(Color.destructive) }
            if isWorking { ProgressView() }
        }
        .disabled(isWorking)
        .interactiveDismissDisabled(isWorking)
        .task {
            let roster: [RSVP]
            do { roster = try await environment.rsvps.approvedOnce(matchId: match.id ?? "") }
            catch { message = "Couldn't load joined Players."; return }
            players = roster.filter { !$0.isHost }
            for player in players {
                reliability[player.userId] = (try? await environment.reliability.reliability(userId: player.userId))?.label
            }
        }
    }

    private func transfer() async {
        guard !isWorking else { return }
        isWorking = true
        message = nil
        defer { isWorking = false }
        guard let hostId = session.user?.id, let player = players.first(where: { $0.userId == selected }) else { return }
        do {
            try await environment.matches.transferHost(match, to: player, hostId: hostId)
            dismiss()
        } catch {
            message = "Couldn't transfer this Match."
        }
    }
}
