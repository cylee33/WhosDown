import SwiftUI

/// Signed out → Welcome (1.2). Signed in or Guest → the tab bar, with onboarding (1.4) covering it
/// until the Player finishes and the Guest gate (1.3) as a sheet. Keeping one tab bar for both means
/// a Guest who upgrades stays where they were.
struct RootView: View {
    @Environment(Session.self) private var session

    var body: some View {
        @Bindable var session = session
        switch session.state {
        case .loading:
            ProgressView()
        case .signedOut:
            WelcomeView()
        case .active:
            MainTabView()
                .sheet(item: $session.gateRoute) { _ in
                    GuestGateSheet()
                }
                .fullScreenCover(isPresented: .constant(session.needsOnboarding)) {
                    OnboardingFlowView()
                }
        }
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
                DiscoverView()
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
                    CreateMatchView()
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
