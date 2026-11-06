import SwiftUI

/// H16 Match chat (1.20). No media button in V1.
struct MatchChatView: View {
    let matchId: String
    let title: String
    let hostId: String
    var playerCount: Int = 0

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: MatchChatViewModel?

    var body: some View {
        VStack(spacing: 0) {
            if let viewModel {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.s) {
                            if viewModel.visible.count >= 50 {
                                Button("Load older") { Task { await viewModel.loadOlder() } }
                                    .font(.footnote)
                            }
                            ForEach(viewModel.visible) { message in
                                MessageBubble(
                                    message: message,
                                    isMine: message.senderId == session.user?.id,
                                    isHost: message.senderId == hostId
                                )
                                .id(message.id)
                            }
                        }
                        .padding(Spacing.m)
                    }
                    .onChange(of: viewModel.visible.count) { _, _ in
                        if let last = viewModel.visible.last?.id { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive).padding(.horizontal, Spacing.m)
                }
                HStack(spacing: Spacing.xs) {
                    TextField("Message Players…", text: Bindable(viewModel).draft, axis: .vertical)
                        .lineLimit(1...4)
                    Button("Send") { Task { await viewModel.send() } }
                        .disabled(viewModel.isSending)
                }
                .padding(Spacing.s)
            } else {
                ProgressView()
            }
        }
        .background(Color.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(title).font(.headline)
                    Text("Match chat · \(playerCount) Players").font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
        }
        .task {
            guard let user = session.user, let name = session.profile?.displayName else { return }
            let viewModel = MatchChatViewModel(
                matchId: matchId, senderId: user.id, senderName: name, chat: environment.chat
            )
            self.viewModel = viewModel
            await viewModel.start()
        }
    }
}
