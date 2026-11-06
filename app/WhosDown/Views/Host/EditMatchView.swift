import SwiftUI

/// H46 Edit Match (1.18).
struct EditMatchView: View {
    let match: Match

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var start: Date
    @State private var end: Date
    @State private var limit: Int
    @State private var joinType: JoinType
    @State private var notes: String
    @State private var venue: Venue?
    @State private var notify = true
    @State private var hostNote = ""
    @State private var message: String?
    @State private var choosingLocation = false

    init(match: Match) {
        self.match = match
        _start = State(initialValue: match.startTime)
        _end = State(initialValue: match.endTime)
        _limit = State(initialValue: match.playerLimit)
        _joinType = State(initialValue: match.joinType)
        _notes = State(initialValue: match.notes ?? "")
    }

    var body: some View {
        Form {
            DatePicker("Start", selection: $start)
            DatePicker("End", selection: $end)
            Stepper("Player limit \(limit)", value: $limit, in: match.joinedCount...50)
            Text("\(match.joinedCount) Players have joined").font(.footnote).foregroundStyle(Color.textSecondary)
            Picker("Join type", selection: $joinType) {
                Text("Open").tag(JoinType.open)
                Text("Approval required").tag(JoinType.approvalRequired)
            }
            Button(venue?.name ?? match.venueName) { choosingLocation = true }
            TextField("Description", text: $notes, axis: .vertical)
            Toggle("Notify joined Players about these changes", isOn: $notify)
            TextField("Note to Players", text: $hostNote)
            if let message { Text(message).foregroundStyle(Color.destructive) }
            Button("Save changes") { Task { await save() } }
        }
        .navigationTitle("Edit Match")
        .navigationDestination(isPresented: $choosingLocation) {
            ChooseLocationView { venue = $0; choosingLocation = false }
        }
    }

    private func save() async {
        guard let hostId = session.user?.id else { return }
        let edits = MatchEdits(
            startTime: start, endTime: end, playerLimit: limit, joinType: joinType,
            notes: ProfileRules.trimmedOrNil(notes), venue: venue, notify: notify,
            hostNote: ProfileRules.trimmedOrNil(hostNote)
        )
        do {
            let players = try await environment.rsvps.approvedOnce(matchId: match.id ?? "")
            try await environment.matches.saveEdits(match, edits: edits, recipients: players.map(\.userId), hostId: hostId)
            let free = edits.joinType == .open ? max(edits.playerLimit - match.joinedCount, 0) : 0
            let promoted = WaitlistRules.promotedIds(
                joinType: edits.joinType, waitlistIds: match.waitlistIds, spotsOpened: free, hasStarted: match.startTime <= .now
            )
            for userId in promoted {
                try await environment.rsvps.approveFromWaitlist(matchId: match.id ?? "", userId: userId, hostId: hostId)
            }
            dismiss()
        } catch {
            message = "Couldn't save those changes."
        }
    }
}

/// H38 Cancel confirmation (1.18).
struct CancelMatchSheet: View {
    let match: Match

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Cancel this Match?").font(.title2.bold())
            Text("Everyone will be notified immediately.").foregroundStyle(Color.textSecondary)
            TextField("Reason", text: $reason)
            if let message { Text(message).font(.footnote).foregroundStyle(Color.destructive) }
            Button("Cancel Match") { Task { await cancel() } }.buttonStyle(.destructive)
            Button("Keep Match") { dismiss() }.buttonStyle(.secondary)
        }
        .padding(Spacing.m)
    }

    private func cancel() async {
        guard let hostId = session.user?.id else { return }
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...200).contains(trimmed.count) else {
            message = "Add a reason."
            return
        }
        do {
            let players = try await environment.rsvps.participants(matchId: match.id ?? "")
            let recipients = players.filter { [.approved, .pending, .waitlisted].contains($0.status) }.map(\.userId)
            try await environment.matches.cancel(match, reason: trimmed, recipients: recipients, hostId: hostId)
            dismiss()
        } catch {
            message = "Couldn't cancel this Match."
        }
    }
}
