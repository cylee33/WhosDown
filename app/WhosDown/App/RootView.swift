import SwiftUI

/// Signed out → Welcome (1.2). Signed in or Guest → the tab bar, with onboarding (1.4) covering it
/// until the Player finishes. Keeping one tab bar for both means a Guest who upgrades stays where they were (1.3).
struct RootView: View {
    @Environment(Session.self) private var session

    var body: some View {
        switch session.state {
        case .loading:
            ProgressView()
        case .signedOut:
            WelcomeView()
        case .active:
            MainTabView()
                .fullScreenCover(isPresented: .constant(session.needsOnboarding)) {
                    OnboardingFlowView()
                }
        }
    }
}

/// Four tabs in V1; the wireframes' Friends tab returns in V2 (1.1, D46).
struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "map") {
                DiscoverView()
            }
            Tab("Matches", systemImage: "sportscourt") {
                MyMatchesView()
            }
            Tab("Create", systemImage: "plus.circle") {
                CreateMatchView()
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView()
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
