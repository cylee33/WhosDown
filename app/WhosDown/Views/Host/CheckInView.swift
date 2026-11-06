import SwiftUI

/// Host check-in (1.27). No Figma frame; built from the roster rows.
struct CheckInView: View {
    let match: Match

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var rows: [RSVP] = []
    @State private var attended: [String: Bool] = [:]
    @State private var message: String?
    @State private var saved = false

    private var open: Bool { CheckInRules.isOpen(match) }
    private var attendedCount: Int { rows.filter { attended[$0.userId] ?? true }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("\(match.title) · \(MatchFormatting.when(match))")
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
                Text("\(attendedCount) of \(rows.count) attended").font(.title2.bold())
                ForEach(rows) { row in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(row.displayName).font(.body.weight(.semibold))
                            Text(row.isHost ? "Host · attended" : row.skillLevel.displayName)
                                .font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        if row.isHost {
                            Text("Attended").font(.footnote).foregroundStyle(Color.statusApproved)
                        } else if open {
                            Toggle("Attended", isOn: binding(for: row.userId))
                                .labelsHidden()
                        } else {
                            Text((attended[row.userId] ?? false) ? "Attended" : "Didn't attend")
                                .font(.footnote)
                        }
                    }
                    .card()
                }
                Text("Reliability reflects attendance, not playing skill.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
                if let message { Text(message).font(.footnote).foregroundStyle(Color.destructive) }
                if open {
                    Button(saved ? "Update check-in" : "Submit check-in") { Task { await submit() } }
                        .buttonStyle(.primary)
                }
            }
            .padding(Spacing.m)
        }
        .background(Color.background)
        .navigationTitle("Check in")
        .task {
            let roster = CheckInRules.rows((try? await environment.rsvps.approvedOnce(matchId: match.id ?? "")) ?? [])
            rows = roster
            for row in roster {
                attended[row.userId] = row.attended ?? true
            }
            saved = match.checkedInAt != nil
        }
    }

    private func binding(for userId: String) -> Binding<Bool> {
        Binding(get: { attended[userId] ?? true }, set: { attended[userId] = $0 })
    }

    private func submit() async {
        guard let hostId = session.user?.id else { return }
        do {
            try await environment.matches.checkIn(match, attendedByPlayer: attended, hostId: hostId)
            saved = true
        } catch {
            message = "Couldn't save check-in."
        }
    }
}
