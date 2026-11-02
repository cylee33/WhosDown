import SwiftUI

@main
struct WhosDownApp: App {
    @State private var environment: AppEnvironment
    @State private var session: Session

    init() {
        FirebaseSetup.configure()
        let environment = AppEnvironment.live()
        _environment = State(initialValue: environment)
        _session = State(initialValue: Session(auth: environment.auth))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(session)
                .task { await session.start() }
        }
    }
}
