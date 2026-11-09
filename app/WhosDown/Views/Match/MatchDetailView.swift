import SwiftUI

/// H09 Match details (1.8). Live: edits and cancellations show at once.
/// Phase 4 fills the action area (Join / Request to join / waitlist / Leave; "Manage Match" for the Host).
struct MatchDetailView: View {
    let matchId: String
    var onFindSimilar: (Sport) -> Void = { _ in }

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MatchDetailViewModel?
    @State private var joinModel: MatchJoinViewModel?
    @State private var showManage = false
    @State private var showChat = false
    @State private var showCalendar = false
    @State private var showReport = false

    var body: some View {
        Group {
            if let viewModel, let match = viewModel.match {
                if joinModel?.action(for: match, isGuest: session.isGuest, userId: session.user?.id) == .status(.approved),
                   !viewModel.isHost, match.status == .scheduled, match.endTime > .now {
                    joined(match)
                } else {
                    details(match, viewModel)
                }
            } else if viewModel?.state == .missing || viewModel?.state == .failed {
                ContentUnavailableView("This Match is no longer available", systemImage: "calendar.badge.exclamationmark")
            } else {
                ProgressView()
            }
        }
        .background(Color.background)
        .navigationTitle(showsJoined ? "Your Match" : "Match details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let match = viewModel?.match {
                        if canAddCalendar(match) {
                            Button("Add to calendar", systemImage: "calendar.badge.plus") { showCalendar = true }
                        }
                        Button("Report Match", systemImage: "flag") {
                            session.requireAccount { showReport = true }
                        }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
                .accessibilityLabel("Match actions")
            }
        }
        .sheet(isPresented: $showCalendar) {
            if let match = viewModel?.match, canAddCalendar(match) {
                CalendarSheet(match: match, address: viewModel?.venueAddress)
            }
        }
        .navigationDestination(isPresented: $showReport) { ReportView(matchId: matchId) }
        .task(id: matchId) {
            let viewModel = MatchDetailViewModel(
                matchId: matchId, userId: session.user?.id, matches: environment.matches,
                reliability: environment.reliability, location: environment.location, venues: environment.venues
            )
            let joinModel = MatchJoinViewModel(matchId: matchId, userId: session.user?.id, rsvps: environment.rsvps)
            self.viewModel = viewModel
            self.joinModel = joinModel
            async let matchTask: Void = viewModel.start()
            async let joinTask: Void = joinModel.start()
            _ = await (matchTask, joinTask)
        }
        .navigationDestination(isPresented: $showManage) {
            HostDashboardView(matchId: matchId)
        }
        .navigationDestination(isPresented: $showChat) {
            MatchChatView(
                matchId: matchId,
                title: viewModel?.match?.title ?? "Match chat",
                hostId: viewModel?.match?.hostId ?? "",
                playerCount: viewModel?.match?.joinedCount ?? 0
            )
        }
        .sheet(isPresented: reviewPresented) {
            if let match = viewModel?.match, let joinModel {
                JoinReviewSheet(
                    match: match, note: Bindable(joinModel).note, isWorking: joinModel.isWorking, errorMessage: joinModel.errorMessage,
                    onSend: {
                        session.requireAccount {
                            Task { await joinModel.sendRequest(player: session.profile, match: match) }
                        }
                    },
                    onClose: { joinModel.showReview = false }
                )
            }
        }
        .sheet(isPresented: leavePresented) {
            if joinModel?.myRSVP?.status == .pending {
                CancelRequestSheet(
                    isWorking: joinModel?.isWorking ?? false, errorMessage: joinModel?.errorMessage,
                    onCancel: { Task { await joinModel?.leave() } },
                    onKeep: { joinModel?.showLeave = false }
                )
            } else {
                LeaveSheet(
                    isWorking: joinModel?.isWorking ?? false, errorMessage: joinModel?.errorMessage,
                    onLeave: { Task { await joinModel?.leave() } },
                    onKeep: { joinModel?.showLeave = false }
                )
            }
        }
    }

    private func canAddCalendar(_ match: Match) -> Bool {
        !session.isGuest && CalendarEventBuilder.canAdd(match, userId: session.user?.id, approved: joinModel?.myRSVP?.status == .approved)
    }

    private var showsJoined: Bool {
        guard let match = viewModel?.match, let joinModel, viewModel?.isHost == false else { return false }
        guard match.status == .scheduled, match.endTime > .now else { return false }
        return joinModel.action(for: match, isGuest: session.isGuest, userId: session.user?.id) == .status(.approved)
    }

    private func joined(_ match: Match) -> some View {
        JoinedMatchView(match: match, onLeave: { joinModel?.showLeave = true }, onChat: { showChat = true }, onCalendar: { showCalendar = true })
            .overlay(alignment: .bottom) {
                if let message = joinModel?.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive).padding(Spacing.s)
                }
            }
    }

    private func details(_ match: Match, _ viewModel: MatchDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Image(systemName: match.sport.symbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))
                    .accessibilityHidden(true)

                if viewModel.isCancelled {
                    Label("Cancelled: \(match.cancelReason ?? "The Host cancelled this Match.")", systemImage: "xmark.octagon")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.statusDeclined)
                        .padding(Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statusDeclinedSoft, in: .rect(cornerRadius: Radius.button))
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(match.title).font(.title.bold()).foregroundStyle(Color.textPrimary)
                    WrappingHStack {
                        Chip(text: MatchFormatting.price(match), foreground: .textPrimary, background: .border.opacity(0.5))
                        Chip(text: match.joinType == .open ? "Open" : "Approval", foreground: .info, background: .info.opacity(0.1))
                        Chip(text: match.skillLevel.displayName)
                    }
                    Text(MatchFormatting.dateRange(match)).font(.headline).foregroundStyle(Color.textPrimary)
                    Text([match.venueName, viewModel.distance].compactMap { $0 }.joined(separator: " · "))
                        .foregroundStyle(Color.textSecondary)
                    if !viewModel.hasEnded {
                        WeatherLine(location: match.location, date: match.startTime, isIndoor: match.isIndoor)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("VENUE").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                    Text(viewModel.venueFacts.joined(separator: " · ")).foregroundStyle(Color.textPrimary)
                    if let note = match.facilityNote {
                        Text(note).font(.footnote).foregroundStyle(Color.textSecondary)
                    }
                    if let notes = match.notes {
                        Text(notes).font(.footnote).foregroundStyle(Color.textSecondary)
                    }
                }
                .card()

                NavigationLink { RosterView(match: match) } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("PLAYERS").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(MatchFormatting.spots(match)).font(.caption.weight(.semibold))
                                .foregroundStyle(match.isFull ? Color.statusWaitlisted : Color.brand)
                        }
                        HStack(spacing: -Spacing.xs) {
                            ForEach(Array(match.attendeePreview.enumerated()), id: \.offset) { _, initials in
                                Text(initials)
                                    .font(.caption.weight(.semibold)).foregroundStyle(Color.brand)
                                    .frame(width: 36, height: 36)
                                    .background(Color.brandSoft, in: .circle)
                                    .overlay(Circle().stroke(Color.surface, lineWidth: 2))
                            }
                            if match.joinedCount > match.attendeePreview.count {
                                Text("+\(match.joinedCount - match.attendeePreview.count)")
                                    .font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                                    .padding(.leading, Spacing.s)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
                        }
                    }
                    .card()
                }
                .buttonStyle(.plain)

                NavigationLink { PlayerProfileView(userId: match.hostId, matchId: match.id) } label: {
                    HStack(spacing: Spacing.s) {
                        AvatarView(photoURL: nil, initials: initials(of: match.hostName), size: 44)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("\(match.hostName) · Host").font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                            Text(viewModel.hostReliability?.label ?? " ").font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
                    }
                    .card()
                }
                .buttonStyle(.plain)

                if viewModel.hasEnded {
                    Text("This Match has ended and moved to Past Matches.")
                        .font(.footnote).foregroundStyle(Color.textSecondary)
                } else if !viewModel.isCancelled {
                    Text("Matches move to Past Matches after they end.")
                        .font(.footnote).foregroundStyle(Color.textSecondary)
                }

                if let joinModel {
                    MatchActionArea(
                        match: match,
                        action: joinModel.action(for: match, isGuest: session.isGuest, userId: session.user?.id),
                        rsvp: joinModel.myRSVP,
                        isWorking: joinModel.isWorking,
                        onJoin: {
                            session.requireAccount {
                                Task { await joinModel.join(player: session.profile, match: match) }
                            }
                        },
                        onRequest: {
                            session.requireAccount { joinModel.showReview = true }
                        },
                        onLeave: { joinModel.showLeave = true },
                        onWaitlist: {
                            session.requireAccount {
                                Task { await joinModel.joinWaitlist(player: session.profile, match: match) }
                            }
                        },
                        onFindSimilar: { onFindSimilar(match.sport) },
                        onBack: { dismiss() },
                        onManage: { showManage = true }
                    )
                    if let message = joinModel.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                }
            }
            .padding(Spacing.m)
        }
    }

    private var reviewPresented: Binding<Bool> {
        Binding(get: { joinModel?.showReview ?? false }, set: { joinModel?.showReview = $0 })
    }

    private var leavePresented: Binding<Bool> {
        Binding(get: { joinModel?.showLeave ?? false }, set: { joinModel?.showLeave = $0 })
    }

    private func initials(of name: String) -> String {
        name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
    }
}

/// H11 Who's going (1.10).
struct RosterView: View {
    let match: Match

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: RosterViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(viewModel.subtitle).font(.subheadline).foregroundStyle(Color.textSecondary)
                    Text(viewModel.joinedText).font(.title2.bold()).foregroundStyle(Color.textPrimary)
                    if viewModel.players.isEmpty && viewModel.errorMessage == nil {
                        ContentUnavailableView("No Players to show", systemImage: "person.2")
                    }
                    ForEach(viewModel.players) { rsvp in
                        NavigationLink { PlayerProfileView(userId: rsvp.userId, matchId: match.id) } label: {
                            PlayerRow(name: rsvp.displayName, detail: viewModel.detail(for: rsvp))
                        }
                        .buttonStyle(.plain)
                    }
                    if let message = viewModel.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                    Text("Reliability reflects attendance, not playing skill.")
                        .font(.footnote).foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity).padding(.top, Spacing.s)
                }
                .padding(Spacing.m)
            } else {
                ProgressView().padding(Spacing.xl)
            }
        }
        .background(Color.background)
        .navigationTitle("Who's going")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let viewModel = RosterViewModel(match: match, rsvps: environment.rsvps, reliability: environment.reliability)
            self.viewModel = viewModel
            await viewModel.start()
        }
    }
}

/// A Player in a list: initials, name, one detail line, chevron (H11, later H21 and H22).
struct PlayerRow: View {
    let name: String
    let detail: String

    var body: some View {
        HStack(spacing: Spacing.s) {
            AvatarView(photoURL: nil, initials: name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined(), size: 44)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                Text(detail).font(.footnote).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview("H09") {
    let environment = AppEnvironment.preview()
    NavigationStack {
        MatchDetailView(matchId: "m1")
    }
    .environment(environment)
    .environment(Session(auth: environment.auth, users: environment.users))
}

#Preview("H11") {
    let environment = AppEnvironment.preview()
    NavigationStack {
        RosterView(match: Match.samples[0])
    }
    .environment(environment)
}
