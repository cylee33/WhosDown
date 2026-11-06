import SwiftUI

/// The in-app inbox (1.21). One list for every V1 type.
struct NotificationsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var items: [AppNotification] = []
    @State private var selected: AppNotification?

    var body: some View {
        List {
            ForEach(items) { item in
                Button {
                    selected = item
                    if let id = item.id { Task { try? await environment.notifications.markRead(userId: session.user?.id ?? "", notificationId: id) } }
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.type.rawValue.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(color(item.type))
                        Text(item.title).font(item.isRead ? .body : .body.weight(.bold))
                        Text(item.body).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                for index in offsets {
                    if let id = items[index].id {
                        Task { try? await environment.notifications.delete(userId: session.user?.id ?? "", notificationId: id) }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            Button("Mark all as read") {
                let ids = items.compactMap(\.id)
                Task { try? await environment.notifications.markAllRead(userId: session.user?.id ?? "", ids: ids) }
            }
        }
        .navigationDestination(item: $selected) { item in
            NotificationDetailView(item: item)
        }
        .task {
            guard let userId = session.user?.id else { return }
            do {
                for try await value in environment.notifications.inbox(userId: userId) {
                    items = value
                }
            } catch {
                items = []
            }
        }
    }

    private func color(_ type: NotificationType) -> Color {
        switch type {
        case .approved, .hostTransferred: .statusApproved
        case .declined, .matchCancelled: .statusDeclined
        case .matchUpdated: .info
        case .spotOpened: .statusWaitlisted
        }
    }
}

struct NotificationDetailView: View {
    let item: AppNotification

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(item.title).font(.title2.bold())
                if let changes = item.changes {
                    ForEach(Array(changes.enumerated()), id: \.offset) { _, change in
                        Text("\(change.field): \(change.oldValue) → \(change.newValue)")
                    }
                }
                if let note = item.hostNote, !note.isEmpty {
                    Text(note).foregroundStyle(Color.textSecondary)
                }
                Text(item.body)
                if let matchId = item.matchId {
                    NavigationLink("View Match") { MatchDetailView(matchId: matchId) }
                    if item.type == .approved || item.type == .matchUpdated {
                        NavigationLink("Open Match chat") {
                            MatchChatView(matchId: matchId, title: item.title, hostId: "")
                        }
                    }
                }
            }
            .padding(Spacing.m)
        }
        .navigationTitle(item.type == .matchCancelled ? "Cancelled" : "Update")
    }
}

struct BellButton: View {
    var count: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "bell")
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold()).foregroundStyle(.white)
                            .padding(4).background(Color.destructive, in: .circle)
                            .offset(x: 8, y: -8)
                    }
                }
        }
        .accessibilityLabel(count == 0 ? "Notifications" : "Notifications, \(count) unread")
    }
}
