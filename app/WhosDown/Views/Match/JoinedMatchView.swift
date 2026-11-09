import SwiftUI

/// H14 after an Open join or an approval, with Match chat and the system Calendar editor.
struct JoinedMatchView: View {
    let match: Match
    var onLeave: () -> Void
    var onChat: () -> Void
    var onCalendar: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var showRemindersOff = false

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
                    if match.status == .scheduled && match.startTime > .now {
                        Button("Calendar", action: onCalendar).buttonStyle(.secondary)
                    }
                    if showRemindersOff {
                        Text("Reminders are off. Turn on notifications in Settings.")
                            .font(.footnote).foregroundStyle(Color.textSecondary)
                    }
                    if let message = environment.reminders.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
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
        .task {
            let key = "remindersOffShown-\(session.user?.id ?? "")"
            if environment.reminders.denied && !UserDefaults.standard.bool(forKey: key) {
                showRemindersOff = true
                UserDefaults.standard.set(true, forKey: key)
            }
        }
        .onChange(of: environment.reminders.denied) { _, denied in
            let key = "remindersOffShown-\(session.user?.id ?? "")"
            if denied && !UserDefaults.standard.bool(forKey: key) {
                showRemindersOff = true
                UserDefaults.standard.set(true, forKey: key)
            }
        }
    }
}
