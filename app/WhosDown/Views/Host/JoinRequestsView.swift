import SwiftUI

/// H21 Join requests (1.15). The Waitlist section is added by 1.17.
struct JoinRequestsView: View {
    @Bindable var viewModel: HostDashboardViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var actionLayout: AnyLayout { dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Spacing.xs)) : AnyLayout(HStackLayout(spacing: Spacing.xs)) }
    @State private var declineMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let match = viewModel.match {
                    Text("\(viewModel.requests.count) waiting · \(match.spotsLeft) spots left")
                        .font(.subheadline).foregroundStyle(Color.textSecondary)
                }
                if viewModel.requests.isEmpty {
                    ContentUnavailableView("No requests", systemImage: "person.crop.circle.badge.questionmark",
                                           description: Text("New requests show up here."))
                }
                ForEach(viewModel.requests) { request in
                    requestCard(request)
                }
                if !viewModel.waitlist.isEmpty {
                    Text("WAITLIST").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                    ForEach(viewModel.waitlist) { person in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(person.displayName).font(.body.weight(.semibold))
                            Text("\(viewModel.reliability[person.userId]?.label ?? "New player") · \(person.skillLevel.displayName)")
                                .font(.footnote).foregroundStyle(Color.textSecondary)
                            Button("Approve") { Task { await viewModel.approveWaitlist(person) } }
                                .buttonStyle(.primary)
                                .disabled(viewModel.isFull || viewModel.isWorking)
                        }
                        .card()
                    }
                }
                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive)
                }
            }
            .padding(Spacing.m)
        }
        .overlay { if viewModel.isWorking { ProgressView() } }
        .background(Color.background)
        .navigationTitle("Join requests")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.declining) { request in
            DeclineSheet(
                name: request.displayName, message: $declineMessage, isWorking: viewModel.isWorking, errorMessage: viewModel.errorMessage,
                onDecline: {
                    Task {
                        await viewModel.decline(request, message: declineMessage)
                        declineMessage = ""
                    }
                },
                onKeep: { viewModel.declining = nil }
            )
        }
    }

    private func requestCard(_ request: RSVP) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(request.displayName).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
            Text("\(viewModel.reliability[request.userId]?.label ?? "New player") · \(request.skillLevel.displayName)")
                .font(.footnote).foregroundStyle(Color.textSecondary)
            if let note = request.noteToHost, !note.isEmpty {
                Text(note).font(.subheadline).foregroundStyle(Color.textPrimary)
            }
            actionLayout {
                Button("Approve") { Task { await viewModel.approve(request) } }
                    .buttonStyle(.primary)
                    .disabled(viewModel.isFull || viewModel.isWorking)
                Button("Decline") {
                    declineMessage = ""
                    viewModel.declining = request
                }
                .buttonStyle(.secondary)
            }
            if viewModel.isFull {
                Text("Match is full").font(.footnote).foregroundStyle(Color.statusWaitlisted)
            }
        }
        .card()
    }
}
