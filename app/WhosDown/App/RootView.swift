import SwiftUI

/// Signed out → Welcome (1.2). Signed in or Guest → the tab bar, with onboarding (1.4) covering it
/// until the Player finishes and the Guest gate (1.3) as a sheet. Keeping one tab bar for both means
/// a Guest who upgrades stays where they were.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session

    var body: some View {
        @Bindable var session = session
        @Bindable var reminders = environment.reminders
        switch session.state {
        case .loading:
            ProgressView()
        case .signedOut:
            WelcomeView()
        case .active:
            activeContent
                .overlay(alignment: .top) {
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["WHOSDOWN_DELIVERY_PROBE"] != nil && environment.reminders.deliveryProbeReady {
                        Text("Reminder probe scheduled").font(.caption).accessibilityIdentifier("delivery-probe-ready")
                    }
                    #endif
                }
                .onAppear {
                    #if DEBUG
                    if let id = ProcessInfo.processInfo.environment["WHOSDOWN_DEV_NOTIFICATION_MATCH_ID"] {
                        environment.reminders.openMatch(from: ["matchId": id])
                    }
                    #endif
                }
                .sheet(isPresented: Binding(get: { reminders.openedMatchId != nil }, set: { if !$0 { reminders.openedMatchId = nil } })) {
                    NavigationStack {
                        if let id = reminders.openedMatchId {
                            MatchDetailView(matchId: id)
                                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { reminders.openedMatchId = nil } } }
                        }
                    }
                }
                .sheet(item: $session.gateRoute) { _ in
                    GuestGateSheet()
                }
                .fullScreenCover(isPresented: .constant(session.needsOnboarding)) {
                    OnboardingFlowView()
                }
        }
    }
    @ViewBuilder
    private var activeContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["WHOSDOWN_SCREEN_AUDIT"] == "1" {
            ScreenAuditView()
        } else if let id = ProcessInfo.processInfo.environment["WHOSDOWN_DEV_MATCH_ID"] {
            NavigationStack { MatchDetailView(matchId: id) }
        } else {
            MainTabView()
        }
        #else
        MainTabView()
        #endif
    }

}

extension Session.GateRoute: Identifiable {
    var id: Self { self }
}

/// Four tabs in V1; the wireframes' Friends tab returns in V2 (1.1, D46).
struct MainTabView: View {
    enum TabID: String { case discover, matches, create, profile }

    @Environment(Session.self) private var session
    #if DEBUG
    // Launch with WHOSDOWN_DEV_TAB=profile (or matches, create) to open on that tab.
    @State private var selection = TabID(rawValue: ProcessInfo.processInfo.environment["WHOSDOWN_DEV_TAB"] ?? "") ?? .discover
    #else
    @State private var selection = TabID.discover
    #endif

    var body: some View {
        TabView(selection: $selection) {
            Tab("Discover", systemImage: "map", value: TabID.discover) {
                DiscoverView(onCreateMatch: { selection = .create })
            }
            Tab("Matches", systemImage: "sportscourt", value: TabID.matches) {
                if session.isGuest {
                    GuestPromptView(
                        title: "Your Matches live here",
                        message: "Create an account to join Matches and see them in one place.",
                        systemImage: "sportscourt"
                    )
                } else {
                    MyMatchesView()
                }
            }
            Tab("Create", systemImage: "plus.circle", value: TabID.create) {
                if session.isGuest {
                    GuestPromptView(
                        title: "Host your own Match",
                        message: "Create an account to host a Match and choose who plays.",
                        systemImage: "plus.circle"
                    )
                } else {
                    CreateMatchView(onBackToDiscover: { selection = .discover })
                }
            }
            Tab("Profile", systemImage: "person.crop.circle", value: TabID.profile) {
                if session.isGuest {
                    GuestProfileView()
                } else {
                    ProfileView()
                }
            }
        }
    }
}

#Preview("Signed in") {
    let environment = AppEnvironment.preview()
    MainTabView()
        .environment(environment)
        .environment(Session(auth: environment.auth, users: environment.users))
}
