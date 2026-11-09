#if DEBUG
import SwiftUI

/// Fixture-driven rendering of every V1 screen, using the actual production views.
/// Only reachable by the UI audit launch flag; all repositories inside this harness are fakes.
struct ScreenAuditView: View {
    private static let screens = [
        "H01 Welcome", "H02 Create account", "H41 Sign in", "H34 Guest gate",
        "H03 Sports", "H42 Levels", "H04 Complete profile", "H05 Permissions", "H44 Onboarding done",
        "H06 Discover map", "H07 Discover list", "H08 Filters", "H09 Match details", "H11 Roster", "H10 Player profile",
        "H12 Join review", "H13 Pending", "H14 Joined", "H35 Declined", "H15 Waitlist", "H37 Leave", "Cancel request", "H16 Chat",
        "H17 Essentials", "H40 Choose location", "New Venue", "H18 Venue details", "H19 Review", "H45 Created",
        "H20 Host dashboard", "H21 Join requests", "Decline request", "H46 Edit Match", "H38 Cancel Match", "H22 Transfer host", "Check in",
        "H27 My Matches", "H28 Past Matches", "H36 Profile", "H49 Edit profile", "Guest profile", "H33 Report", "H50 Inbox", "H51 Update", "H52 Cancellation",
    ]
    @State private var index = Int(ProcessInfo.processInfo.environment["WHOSDOWN_AUDIT_START"] ?? "") ?? 0
    @State private var fixtures = AuditFixtures()
    private var name: String { Self.screens[index] }
    private var isSheet: Bool { [3, 11, 15, 20, 21, 25, 31, 33, 34].contains(index) }
    private var ownsNavigation: Bool { [0, 3, 9, 10, 11, 36, 37, 38, 40].contains(index) }

    var body: some View {
        Group {
            if fixtures.session.user == nil { ProgressView() }
            else if index == Self.screens.count { Text("Screen audit complete").accessibilityIdentifier("audit-complete") }
            else if isSheet {
                Color.background.sheet(isPresented: .constant(true)) {
                    VStack(spacing: 0) {
                        controls
                        screen
                    }
                }
            } else if ownsNavigation {
                screen.safeAreaInset(edge: .bottom) { controls }
            } else {
                NavigationStack { screen.navigationTitle(name).navigationBarTitleDisplayMode(.inline) }
                    .safeAreaInset(edge: .bottom) { controls }
            }
        }
        .environment(fixtures.environment)
        .environment(fixtures.session)
        .task { await fixtures.session.start() }
    }

    private var controls: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(index + 1)/\(Self.screens.count) \(name)").font(.caption2)
                .accessibilityIdentifier("audit-screen-title")
            Button("Next audit screen") { index += 1 }.font(.caption)
                .accessibilityIdentifier("audit-next")
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xs).background(Color.surface)
        .dynamicTypeSize(.large)
    }

    @ViewBuilder private var screen: some View {
        switch index {
        case 0: WelcomeView()
        case 1: CreateAccountView(onSignInInstead: {})
        case 2: SignInView(onCreateAccountInstead: {})
        case 3: GuestGateSheet()
        case 4: SelectSportsView(selectedSports: .constant([.soccer]), customSportName: .constant(""), canContinue: true, onContinue: {})
        case 5: SkillLevelsView(sports: [.soccer], customSportName: "", levels: .constant([.soccer: .allLevels]), canContinue: true, onContinue: {})
        case 6: CompleteProfileView(viewModel: fixtures.onboarding)
        case 7: PermissionsView(viewModel: fixtures.onboarding)
        case 8: OnboardingDoneView(viewModel: fixtures.onboarding)
        case 9: DiscoverView()
        case 10: DiscoverView(initialMode: .list)
        case 11: FiltersSheet(viewModel: fixtures.discover)
        case 12: MatchDetailView(matchId: "browse")
        case 13: RosterView(match: fixtures.browse)
        case 14: PlayerProfileView(userId: "seed_jamie", matchId: "browse")
        case 15: JoinReviewSheet(match: fixtures.browse, note: .constant("Happy to play defense."), isWorking: false, onSend: {}, onClose: {})
        case 16: MatchDetailView(matchId: "pending")
        case 17: MatchDetailView(matchId: "joined")
        case 18: MatchDetailView(matchId: "declined")
        case 19: MatchDetailView(matchId: "waitlist")
        case 20: LeaveSheet(isWorking: false, onLeave: {}, onKeep: {})
        case 21: CancelRequestSheet(isWorking: false, onCancel: {}, onKeep: {})
        case 22: MatchChatView(matchId: "joined", title: "Pickup Soccer", hostId: "seed_jamie", playerCount: 3)
        case 23: EssentialsView(viewModel: fixtures.create)
        case 24: ChooseLocationView(onChosen: { _ in })
        case 25: NewVenueSheet(place: Place(name: "CMU Soccer Field", address: "5000 Forbes Ave", location: .cmu), isWorking: false, onSave: { _, _, _ in })
        case 26: VenueDetailsView(viewModel: fixtures.create)
        case 27: ReviewMatchView(viewModel: fixtures.create, host: .sample)
        case 28: MatchCreatedView(viewModel: fixtures.create, onBackToDiscover: {})
                .task { if fixtures.create.publishedMatchId == nil { await fixtures.create.publish(host: .sample) } }
        case 29: HostDashboardView(matchId: "host")
        case 30: JoinRequestsView(viewModel: fixtures.host).task { await fixtures.host.start() }
        case 31: DeclineSheet(name: "Taylor", message: .constant("Keeping this to experienced Players."), isWorking: false, onDecline: {}, onKeep: {})
        case 32: EditMatchView(match: fixtures.hosted)
        case 33: CancelMatchSheet(match: fixtures.hosted)
        case 34: TransferHostSheet(match: fixtures.hosted)
        case 35: CheckInView(match: fixtures.past)
        case 36: MyMatchesView()
        case 37: MyMatchesView(initialSegment: .past)
        case 38: ProfileView()
        case 39: EditProfileView(viewModel: fixtures.edit, onEditSports: {}, onSave: {})
        case 40: GuestProfileView()
        case 41: ReportView(reportedUserId: "seed_jamie", matchId: "browse", playerName: "Jamie")
        case 42: NotificationsView()
        case 43: NotificationDetailView(item: fixtures.update)
        case 44: NotificationDetailView(item: fixtures.cancellation)
        default: EmptyView()
        }
    }
}

@Observable private final class AuditFixtures {
    let environment: AppEnvironment
    let session: Session
    let browse: Match
    let hosted: Match
    let past: Match
    let onboarding: OnboardingViewModel
    let create: CreateMatchViewModel
    let discover: DiscoverViewModel
    let host: HostDashboardViewModel
    let edit: EditProfileViewModel
    let update: AppNotification
    let cancellation: AppNotification

    init() {
        let environment = AppEnvironment.preview()
        self.environment = environment
        let users = environment.users as! FakeUserRepository
        var jamie = UserProfile.sample
        jamie.id = "seed_jamie"; jamie.displayName = "Jamie Morales"
        users.profiles["seed_jamie"] = jamie
        let defaults = UserDefaults(suiteName: "whosdown-screen-audit")!
        defaults.set(true, forKey: "hasLaunchedBefore")
        session = Session(auth: environment.auth, users: users, defaults: defaults)
        browse = Match.sample(id: "browse", joinedCount: 3)
        var hosted = Match.sample(id: "host", joinedCount: 3)
        hosted.hostId = "seed_alex"; hosted.hostName = "Alex Morgan"
        hosted.waitlistIds = ["seed_sam"]; hosted.waitlistCount = 1
        self.hosted = hosted
        var past = hosted; past.id = "past"; past.startTime = .now.addingTimeInterval(-7200); past.endTime = .now.addingTimeInterval(-1800)
        self.past = past
        var waitlist = Match.sample(id: "waitlist", joinedCount: 4, playerLimit: 4)
        waitlist.waitlistIds = ["seed_alex"]; waitlist.waitlistCount = 1
        (environment.matches as! FakeMatchRepository).matches = [browse, hosted, past, waitlist,
            Match.sample(id: "pending"), Match.sample(id: "joined"), Match.sample(id: "declined")]
        let rsvps = environment.rsvps as! FakeRSVPRepository
        rsvps.approved = Dictionary(uniqueKeysWithValues: ["browse", "host", "past", "joined"].map { ($0, RSVP.samples) })
        rsvps.myApproved = ["seed_alex": ["joined"]]
        var pending = RSVP.sample("seed_taylor", "Taylor Ross", minutesAgo: 5); pending.status = .pending
        var waiting = RSVP.sample("seed_sam", "Sam Lee", minutesAgo: 10); waiting.status = .waitlisted
        rsvps.pending = ["host": [pending]]
        rsvps.waitlisted = ["host": [waiting]]
        for id in ["host", "past"] {
            rsvps.approved[id] = RSVP.samples.map { rsvp in
                var item = rsvp; item.isHost = item.userId == "seed_alex"; return item
            }
        }
        for (id, status) in [("pending", RSVPStatus.pending), ("joined", .approved), ("declined", .declined), ("waitlist", .waitlisted), ("past", .approved)] {
            var item = RSVP.sample("seed_alex", "Alex Morgan", minutesAgo: 20)
            item.status = status; item.hostResponse = status == .declined ? "Keeping tonight to competitive players." : nil
            item.checkedIn = id == "past"; item.attended = id == "past" ? true : nil
            rsvps.mine[id] = item
        }
        (environment.chat as! FakeChatRepository).messages["joined"] = [
            Message(id: "one", senderId: "seed_jamie", senderName: "Jamie", text: "Bring a light and dark shirt. See you at the field!", sentAt: .now),
            Message(id: "two", senderId: "seed_alex", senderName: "Alex", text: "I can bring a ball.", sentAt: .now),
        ]
        update = AppNotification(id: "updated", type: .matchUpdated, title: "Pickup Soccer was updated", body: "Start time and Venue changed.", matchId: "browse", fromUserId: "seed_jamie", changes: [.init(field: "Start time", oldValue: "6 PM", newValue: "7 PM")], hostNote: "Please bring water.", isRead: false, createdAt: .now)
        cancellation = AppNotification(id: "cancelled", type: .matchCancelled, title: "Pickup Soccer was cancelled", body: "Rain all afternoon. Next week instead!", matchId: "browse", fromUserId: "seed_jamie", changes: nil, hostNote: "Rain all afternoon.", isRead: false, createdAt: .now)
        (environment.notifications as! FakeNotificationRepository).inboxItems = [update, cancellation]
        onboarding = OnboardingViewModel(userId: "seed_alex", profile: .sample, users: users, permissions: environment.permissions, progress: defaults)
        create = CreateMatchViewModel(matches: environment.matches)
        create.draft.sport = .soccer; create.draft.venue = Venue.samples[0]; create.draft.notes = "Bring a light and dark shirt."
        discover = DiscoverViewModel(userId: "seed_alex", isGuest: false, matches: environment.matches, rsvps: rsvps, users: users, location: environment.location)
        host = HostDashboardViewModel(matchId: "host", hostId: "seed_alex", matches: environment.matches, rsvps: rsvps, reliability: environment.reliability, chat: environment.chat)
        edit = EditProfileViewModel(userId: "seed_alex", profile: .sample, users: users)
    }
}
#endif
