import SwiftUI

/// H28, shown as the Past segment of My Matches (1.19).
struct PastMatchesView: View {
    let months: [PastMonth]
    var userId: String = ""
    var onOpen: (Match) -> Void

    var body: some View {
        if months.isEmpty {
            ContentUnavailableView("No past Matches yet", systemImage: "clock", description: Text("Matches move here after they end."))
        } else {
            LazyVStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(months) { month in
                    Text("\(month.title) · \(month.matchCount) \(month.matchCount == 1 ? "Match" : "Matches") · \(month.attendedCount) attended")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.textSecondary)
                    ForEach(month.rows) { row in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Button { onOpen(row.match) } label: {
                                MatchListCard(
                                    match: row.match,
                                    badge: MyMatchesSorter.pastBadge(
                                        match: row.match, rsvp: row.rsvp, isHost: row.match.hostId == row.rsvp?.userId || row.rsvp == nil
                                    ).title
                                )
                            }
                            .buttonStyle(.plain)
                            if row.match.hostId == userId, MyMatchesSorter.checkInOpen(row.match) {
                                NavigationLink { CheckInView(match: row.match) } label: {
                                    Text("Check in").font(.footnote.weight(.semibold))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MatchListCard: View {
    let match: Match
    let badge: String

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: match.sport.symbolName)
                .frame(width: 44, height: 44)
                .background(Color.brandSoft, in: .rect(cornerRadius: Radius.button))
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(match.title).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                Text("\(MatchFormatting.when(match)) · \(match.venueName)")
                    .font(.footnote).foregroundStyle(Color.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text(badge).font(.caption2.weight(.bold)).foregroundStyle(Color.textSecondary)
        }
        .card()
    }
}
