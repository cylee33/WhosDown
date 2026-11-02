import Foundation

/// H01 Welcome: "Explore as guest" (1.3) and the Debug-only developer sign-in.
@Observable
final class WelcomeViewModel {
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    private let auth: AuthRepository

    init(auth: AuthRepository) {
        self.auth = auth
    }

    func exploreAsGuest() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await auth.signInAsGuest()
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = error.message
        } catch {
            errorMessage = AuthError.unknown.message
        }
    }

    #if DEBUG
    /// Signs in as the seeded test Player Alex (emulator only).
    func developerSignIn() async {
        do {
            try await auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        } catch {
            errorMessage = "Developer sign-in failed. Is the emulator running and seeded? (npm run emulators, npm run seed)"
        }
    }
    #endif
}
