import Foundation
import SwiftUI

@main
struct WhosDownApp: App {
    @State private var environment: AppEnvironment
    @State private var session: Session
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseSetup.configure()
        let environment = AppEnvironment.live()
        environment.reminders.activate()
        _environment = State(initialValue: environment)
        _session = State(initialValue: Session(auth: environment.auth, users: environment.users))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(session)
                .task {
                    guard NSClassFromString("XCTestCase") == nil else { return }
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["WHOSDOWN_UI_TEST"] == "1" {
                        try? environment.auth.signOut()
                    }
                    #endif
                    await session.start()
                }
                .task(id: "\(String(describing: session.state))-\(session.user?.id ?? "signed-out")-\(session.isGuest)-\(scenePhase == .active)") {
                    guard NSClassFromString("XCTestCase") == nil, scenePhase == .active, session.state != .loading else { return }
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["WHOSDOWN_DELIVERY_PROBE"] != nil {
                        if let userId = session.user?.id {
                            await ReminderDeliveryProbe.prepare(environment: environment, userId: userId)
                        }
                        return
                    }
                    #endif
                    await environment.reminders.bind(userId: session.isGuest ? nil : session.user?.id)
                    guard !Task.isCancelled else { return }
                    let model = ReminderSyncModel(matches: environment.matches, rsvps: environment.rsvps, scheduler: environment.reminders)
                    await model.start(userId: session.isGuest ? nil : session.user?.id)
                }
        }
    }
}
