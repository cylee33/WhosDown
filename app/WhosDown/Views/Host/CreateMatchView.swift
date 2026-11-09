import SwiftUI

/// The Create tab (1.11): H17 → H18 → H19 → H45, with H40 (1.12) for the location.
struct CreateMatchView: View {
    /// Lets H45 "Back to Discover" switch tabs.
    var onBackToDiscover: () -> Void = {}

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: CreateMatchViewModel?

    var body: some View {
        Group {
            if let viewModel {
                flow(viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil { viewModel = CreateMatchViewModel(matches: environment.matches) }
        }
    }

    private func flow(_ viewModel: CreateMatchViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return NavigationStack(path: $viewModel.path) {
            EssentialsView(viewModel: viewModel)
                .navigationDestination(for: CreateMatchViewModel.Step.self) { step in
                    switch step {
                    case .location:
                        ChooseLocationView(onChosen: viewModel.choose)
                    case .details:
                        VenueDetailsView(viewModel: viewModel)
                    case .review:
                        ReviewMatchView(viewModel: viewModel, host: session.profile)
                    case .created:
                        MatchCreatedView(viewModel: viewModel) {
                            viewModel.startOver()
                            onBackToDiscover()
                        }
                    }
                }
        }
    }
}

/// H17 Create Match: the essentials.
struct EssentialsView: View {
    @Bindable var viewModel: CreateMatchViewModel
    @State private var askingForCustomName = false

    var body: some View {
        VStack(spacing: Spacing.none) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Essentials first. Everything else is optional.")
                        .font(.subheadline).foregroundStyle(Color.textSecondary)

                    field("SPORT") {
                        Menu {
                            ForEach(Sport.allCases.filter { $0 != .other }) { sport in
                                Button(sport.displayName) { viewModel.draft.sport = sport }
                            }
                            Button("Other…") { askingForCustomName = true }
                        } label: {
                            HStack {
                                Text(viewModel.draft.sport == nil ? "Choose a sport" : viewModel.draft.sportName)
                                    .foregroundStyle(viewModel.draft.sport == nil ? Color.textSecondary : Color.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").foregroundStyle(Color.textSecondary)
                            }
                            .boxed()
                        }
                        Button("Can't find it? + Add custom activity") { askingForCustomName = true }
                            .font(.footnote.weight(.semibold))
                    }

                    LabeledField(label: "TITLE (OPTIONAL)") {
                        TextField(viewModel.draft.sport == nil ? "Pickup Soccer" : "Pickup \(viewModel.draft.sportName)", text: $viewModel.draft.title)
                    }

                    field("DATE & TIME") {
                        VStack(spacing: Spacing.xs) {
                            DatePicker("Starts", selection: $viewModel.draft.startTime, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                            DatePicker("Ends", selection: $viewModel.draft.endTime, in: viewModel.draft.startTime..., displayedComponents: [.date, .hourAndMinute])
                        }
                        .boxed()
                    }

                    field("LOCATION") {
                        Button { viewModel.path.append(.location) } label: {
                            HStack {
                                Text(viewModel.draft.venue?.name ?? "Choose location")
                                    .foregroundStyle(viewModel.draft.venue == nil ? Color.textSecondary : Color.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
                            }
                            .boxed()
                        }
                        .buttonStyle(.plain)
                    }

                    field("SKILL") {
                        WrappingHStack {
                            ForEach(SkillLevel.allCases) { level in
                                SelectableChip(title: level.displayName, isSelected: viewModel.draft.skillLevel == level) {
                                    viewModel.draft.skillLevel = level
                                }
                            }
                        }
                    }

                    field("PLAYER LIMIT") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Stepper(value: $viewModel.draft.playerLimit, in: MatchDraft.playerLimitRange) {
                                Text("\(viewModel.draft.playerLimit) players").monospacedDigit()
                            }
                            Text("Includes you as the Host.").font(.footnote).foregroundStyle(Color.textSecondary)
                            Toggle("Waitlist when full", isOn: $viewModel.draft.waitlistEnabled).tint(Color.brand)
                        }
                        .boxed()
                    }

                    field("JOIN TYPE") {
                        Picker("Join type", selection: $viewModel.draft.joinType) {
                            Text("Open").tag(JoinType.open)
                            Text("Approval required").tag(JoinType.approvalRequired)
                        }
                        .adaptiveSegmentedPicker()
                    }

                    field("PRICE") {
                        HStack(spacing: Spacing.xs) {
                            SelectableChip(title: "Free", isSelected: !viewModel.draft.isPaid) { viewModel.draft.isPaid = false }
                            SelectableChip(title: "Paid", isSelected: viewModel.draft.isPaid) { viewModel.draft.isPaid = true }
                            if viewModel.draft.isPaid {
                                TextField("$", value: $viewModel.draft.priceDollars, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: 72)
                                    .boxed()
                            }
                        }
                        Text("Shown to Players only; WhosDown doesn't take payments.")
                            .font(.footnote).foregroundStyle(Color.textSecondary)
                    }

                    ProblemList(problems: viewModel.problems)
                }
                .padding(Spacing.m)
            }
            Button("Next: venue & details", action: viewModel.continueFromEssentials)
                .buttonStyle(.primary)
                .padding(Spacing.m)
        }
        .background(Color.background)
        .navigationTitle("Create Match")
        .alert("Name your activity", isPresented: $askingForCustomName) {
            TextField("e.g. Spikeball", text: $viewModel.draft.customSportName)
            Button("Done") { viewModel.draft.sport = .other }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Up to \(ProfileRules.customSportNameLimit) characters.")
        }
    }

    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
            content()
        }
    }
}

/// H18 Venue & details.
struct VenueDetailsView: View {
    @Bindable var viewModel: CreateMatchViewModel

    var body: some View {
        VStack(spacing: Spacing.none) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if let venue = viewModel.draft.venue {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(venue.name).font(.title3.bold()).foregroundStyle(Color.textPrimary)
                            HStack {
                                Chip(text: venue.isIndoor ? "Indoor" : "Outdoor")
                                Chip(text: venue.surface.capitalized)
                                if venue.hasLights { Chip(text: "Lights") }
                            }
                        }
                        .card()
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Toggle("Field reserved", isOn: $viewModel.draft.fieldReserved).tint(Color.brand)
                        if viewModel.draft.fieldReserved {
                            TextField("Reservation window, e.g. 6:45–8:45 PM", text: $viewModel.draft.reservationWindow)
                        }
                    }
                    .boxed()

                    LabeledField(label: "FACILITY NOTE (OPTIONAL)") {
                        TextField("e.g. Tennis club uses the next court until 7:15 PM", text: $viewModel.draft.facilityNote, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.vertical, Spacing.xs)
                    }
                    if let venue = viewModel.draft.venue {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("WEATHER").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                            WeatherLine(location: venue.location, date: viewModel.draft.startTime, isIndoor: venue.isIndoor)
                        }
                    }
                    LabeledField(label: "NOTES (OPTIONAL)") {
                        TextField("e.g. Bring a light + dark shirt", text: $viewModel.draft.notes, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(.vertical, Spacing.xs)
                    }
                    ProblemList(problems: viewModel.problems)
                }
                .padding(Spacing.m)
            }
            Button("Review Match", action: viewModel.continueFromDetails)
                .buttonStyle(.primary)
                .padding(Spacing.m)
        }
        .background(Color.background)
        .navigationTitle("Venue & details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// H19 Review & publish.
struct ReviewMatchView: View {
    let viewModel: CreateMatchViewModel
    let host: UserProfile?

    var body: some View {
        let draft = viewModel.draft
        VStack(spacing: Spacing.none) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(draft.resolvedTitle).font(.title2.bold()).foregroundStyle(Color.textPrimary)
                        Text(viewModel.timeText).foregroundStyle(Color.textPrimary)
                        Text(draft.venue?.name ?? "").foregroundStyle(Color.textSecondary)
                        WrappingHStack {
                            Chip(text: draft.priceText)
                            Chip(text: draft.joinType == .open ? "Open" : "Approval")
                            Chip(text: draft.skillLevel.displayName)
                        }
                    }
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Visible before joining").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                        if let venue = draft.venue {
                            Text(VenueRules.factsLine(venue))
                            WeatherLine(location: venue.location, date: draft.startTime, isIndoor: venue.isIndoor)
                        }
                        Text("\(draft.playerLimit)-player cap · Waitlist \(draft.waitlistEnabled ? "on" : "off")")
                        if draft.fieldReserved {
                            Text("Field reserved\(draft.reservationWindow.isEmpty ? "" : " " + draft.reservationWindow)")
                                .foregroundStyle(Color.brand)
                        }
                        Text("Payment: \(draft.priceText)").fontWeight(.semibold)
                    }
                    .card()

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("After publish").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                        Text("You'll manage approvals, the roster, chat, edits, cancellations, and host transfer from My Matches.")
                            .font(.subheadline).foregroundStyle(Color.textSecondary)
                    }

                    ProblemList(problems: viewModel.problems)
                    if let message = viewModel.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                }
                .padding(Spacing.m)
            }
            WorkingButton(title: "Publish Match", isWorking: viewModel.isPublishing, isEnabled: host != nil) {
                Task { await viewModel.publish(host: host) }
            }
            .padding(Spacing.m)
        }
        .background(Color.background)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// H45 Match created!
struct MatchCreatedView: View {
    let viewModel: CreateMatchViewModel
    let onBackToDiscover: () -> Void

    var body: some View {
        let draft = viewModel.draft
        ScrollView {
        VStack(spacing: Spacing.m) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.brand)
                .frame(width: 88, height: 88)
                .background(Color.brandSoft, in: .circle)
            VStack(spacing: Spacing.xs) {
                Text("Match created!").font(.title.bold()).foregroundStyle(Color.textPrimary)
                Text("\(draft.resolvedTitle) is live and visible to nearby Players.")
                    .font(.subheadline).foregroundStyle(Color.textSecondary).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(draft.resolvedTitle).font(.headline)
                Text(viewModel.timeText).font(.subheadline)
                Text(draft.venue?.name ?? "").font(.subheadline).foregroundStyle(Color.textSecondary)
                WrappingHStack {
                    Chip(text: "1 / \(draft.playerLimit) joined", foreground: .info, background: .info.opacity(0.1))
                    Chip(text: draft.joinType == .open ? "Open" : "Approval ON")
                }
            }
            .card()
            Spacer()
            if let matchId = viewModel.publishedMatchId {
                NavigationLink("Manage Match") { HostDashboardView(matchId: matchId) }
                    .buttonStyle(.primary)
            }
            Button("Back to Discover", action: onBackToDiscover)
                .buttonStyle(.secondary)
        }
        .padding(Spacing.m)
        }
        .background(Color.background)
        .navigationBarBackButtonHidden()
    }
}

/// The reasons "Next" or "Publish" didn't go through, in red.
private struct ProblemList: View {
    let problems: [MatchDraft.Problem]

    var body: some View {
        if !problems.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                ForEach(problems, id: \.self) { problem in
                    Label(problem.message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.destructive)
                }
            }
        }
    }
}

private extension View {
    /// A white rounded box like a text field, for pickers and rows.
    func boxed() -> some View {
        padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 48)
            .background(Color.surface, in: .rect(cornerRadius: Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Color.border))
    }
}

#Preview("H17") {
    let environment = AppEnvironment.preview()
    CreateMatchView()
        .environment(environment)
        .environment(Session(auth: environment.auth, users: environment.users))
}
