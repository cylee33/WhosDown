import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation

/// One switch for where the app's data lives (1.1 rule 3).
/// Debug builds use the local emulator as the demo project `demo-whosdown`, so they can never touch real data.
/// Release builds use `whosdown-57e99` from GoogleService-Info.plist (D40).
enum FirebaseSetup {
    /// The simulator reaches the Mac's emulator at 127.0.0.1. On a real iPhone, change this to the Mac's LAN IP.
    static let emulatorHost = "127.0.0.1"

    static func configure() {
        #if DEBUG
        let options = FirebaseOptions(googleAppID: "1:000000000000:ios:0000000000000000", gcmSenderID: "000000000000")
        options.projectID = "demo-whosdown"
        options.apiKey = "AIzaDemoKeyForLocalEmulatorOnly000000000"
        options.storageBucket = "demo-whosdown.appspot.com"
        FirebaseApp.configure(options: options)

        Auth.auth().useEmulator(withHost: emulatorHost, port: 9099)
        let settings = Firestore.firestore().settings
        settings.host = "\(emulatorHost):8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
        Storage.storage().useEmulator(withHost: emulatorHost, port: 9199)
        #else
        FirebaseApp.configure()
        #endif
    }
}
