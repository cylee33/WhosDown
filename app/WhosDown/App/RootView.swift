import SwiftUI

/// Signed out → Welcome (1.2); signed in → the tab bar.
struct RootView: View {
    @Environment(Session.self) private var session

    var body: some View {
        switch session.state {
        case .loading:
            ProgressView()
        case .signedOut:
            WelcomeView()
        case .signedIn:
            MainTabView()
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
        .environment(Session(auth: environment.auth))
}
