import SwiftUI

/// The in-app inbox (1.21). One list for every V1 type.
struct NotificationsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: NotificationsViewModel?
    private var items: [AppNotification] { viewModel?.items ?? [] }
    @State private var selected: AppNotification?

    var body: some View {
        List {
            ForEach(items) { item in
                Button {
                    selected = item
                    if let id = item.id { Task { await viewModel?.markRead(id) } }
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.type.rawValue.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(color(item.type))
                        Text(item.title).font(item.isRead ? .body : .body.weight(.bold))
                        Text(item.body).font(.footnote).foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let ids = offsets.compactMap { items[$0].id }
                Task { await viewModel?.delete(ids) }
            }
            if let message = viewModel?.errorMessage {
                Text(message).foregroundStyle(Color.destructive)
            }
        }
        .overlay {
            if viewModel == nil || viewModel?.isLoading == true || viewModel?.isWorking == true { ProgressView() }
            else if items.isEmpty && viewModel?.errorMessage == nil {
                ContentUnavailableView("No notifications yet", systemImage: "bell", description: Text("Updates about your Matches will appear here."))
            }
        }
        .disabled(viewModel?.isWorking == true)
        .navigationTitle("Notifications")
        .toolbar {
            Button("Mark all as read") {
                Task { await viewModel?.markAll() }
            }
        }
        .navigationDestination(item: $selected) { item in
            NotificationDetailView(item: item)
        }
        .task {
            guard let userId = session.user?.id else { return }
            let model = NotificationsViewModel(userId: userId, repository: environment.notifications)
            viewModel = model
            await model.start()
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
                            .font(.caption2.bold()).foregroundStyle(Color.onBrand)
                            .padding(Spacing.xxs).background(Color.destructive, in: .circle)
                            .offset(x: Spacing.xs, y: -Spacing.xs)
                    }
                }
        }
        .accessibilityLabel(count == 0 ? "Notifications" : "Notifications, \(count) unread")
    }
}
