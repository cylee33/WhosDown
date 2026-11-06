import SwiftUI

/// H14 after an Open join or an approval (1.13, 1.14 header). Chat and calendar are filled in later.
struct JoinedMatchView: View {
    let match: Match
    var onLeave: () -> Void
    var onChat: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    StatusBadge(status: .approved)
                    Text("You're in for \(match.title)")
                        .font(.title2.bold()).foregroundStyle(Color.textPrimary)
                    Text(MatchFormatting.dateRange(match)).font(.headline).foregroundStyle(Color.textPrimary)
                    Text(match.venueName).foregroundStyle(Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("MATCH-DAY COORDINATION").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                    if let notes = match.notes {
                        Text(notes).foregroundStyle(Color.textPrimary)
                    }
                    Button("Chat", action: onChat).buttonStyle(.secondary)
                    Button("Calendar") {}.buttonStyle(.secondary).disabled(true)
                }
                .card()

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("VENUE").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                    Text(match.venueName).foregroundStyle(Color.textPrimary)
                    WeatherLine(location: match.location, date: match.startTime, isIndoor: match.isIndoor)
                }
                .card()

                Button("Open Match chat", action: onChat).buttonStyle(.primary)

                if match.startTime > .now {
                    Button("Leave Match", action: onLeave).buttonStyle(.destructive)
                    Text("Leaving immediately reopens your spot.")
                        .font(.footnote).foregroundStyle(Color.textSecondary)
                }
            }
            .padding(Spacing.m)
        }
        .background(Color.background)
    }
}
