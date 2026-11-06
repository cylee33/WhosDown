import SwiftUI

/// The join / request / status controls on Match details (1.13, 1.14, 1.16).
struct MatchActionArea: View {
    let match: Match
    let action: JoinAction
    let rsvp: RSVP?
    var isWorking: Bool
    var onJoin: () -> Void
    var onRequest: () -> Void
    var onLeave: () -> Void
    var onWaitlist: () -> Void
    var onFindSimilar: () -> Void
    var onBack: () -> Void
    var onManage: () -> Void

    private var waitlistTitle: String {
        if let userId = rsvp?.userId, let index = match.waitlistIds.firstIndex(of: userId) {
            return "WAITLISTED · #\(index + 1)"
        }
        return "WAITLISTED"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            switch action {
            case .join:
                Button(action: onJoin) {
                    if isWorking { ProgressView().tint(.white) } else { Text("Join") }
                }
                .buttonStyle(.primary)
                .disabled(isWorking)
            case .requestToJoin:
                Button("Request to join", action: onRequest).buttonStyle(.primary)
            case .fullWaitlist:
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("FULL").font(.caption.weight(.bold)).foregroundStyle(Color.statusDeclined)
                    Text("\(match.joinedCount) / \(match.playerLimit) players").font(.headline)
                    Text(match.waitlistCount == 0 ? "Waitlist is enabled for this Match." : "\(match.waitlistCount) people waiting")
                        .font(.subheadline).foregroundStyle(Color.textSecondary)
                    Text(match.joinType == .open
                         ? "If a Player leaves, the next person in line gets the spot automatically."
                         : "If a spot opens, the Host can let you in.")
                        .font(.footnote).foregroundStyle(Color.textSecondary)
                    Button("Join waitlist", action: onWaitlist).buttonStyle(.primary).disabled(isWorking)
                }
                .card()
            case .full:
                Button("Full") {}.buttonStyle(.primary).disabled(true)
                Button("Find similar Matches", action: onFindSimilar).buttonStyle(.secondary)
            case .manage:
                Button("Manage Match", action: onManage).buttonStyle(.primary)
            case .status(let status):
                statusCard(status)
            case .none:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func statusCard(_ status: RSVPStatus) -> some View {
        switch status {
        case .pending:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                StatusBadge(status: .pending)
                Text("Waiting for host approval").font(.headline).foregroundStyle(Color.textPrimary)
                Text("\(match.title) · \(MatchFormatting.when(match))")
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
                Text("We'll notify you when you're approved or declined.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
                if match.startTime > .now {
                    Button("Cancel request", action: onLeave).buttonStyle(.destructive)
                }
            }
            .card()
        case .approved:
            EmptyView()
        case .declined:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                StatusBadge(status: .declined)
                Text("This request wasn't approved").font(.headline).foregroundStyle(Color.textPrimary)
                if let message = rsvp?.hostResponse, !message.isEmpty {
                    Text(message).font(.subheadline).foregroundStyle(Color.textSecondary)
                }
                Button("Find similar All-Level Matches", action: onFindSimilar).buttonStyle(.secondary)
                Button("Back to Discover", action: onBack).buttonStyle(.secondary)
            }
            .card()
        case .waitlisted:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                StatusBadge(title: waitlistTitle, foreground: .statusWaitlisted, background: .statusWaitlistedSoft)
                if match.startTime > .now {
                    Button("Leave waitlist", action: onLeave).buttonStyle(.destructive)
                }
            }
            .card()
        case .left:
            EmptyView()
        }
    }
}
