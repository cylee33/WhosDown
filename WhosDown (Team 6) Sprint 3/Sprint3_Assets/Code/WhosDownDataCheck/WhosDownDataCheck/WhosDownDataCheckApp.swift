import SwiftUI
import FirebaseCore

@main
struct WhosDownDataCheckApp: App {
  init() {
    // Firebase is optional so the Weather and Models tabs work before
    // GoogleService-Info.plist is added.
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
