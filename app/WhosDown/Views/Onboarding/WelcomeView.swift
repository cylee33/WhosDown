import SwiftUI

/// Phase 0 placeholder for H01 Welcome. 1.2 builds the real screen with Create account and Sign in;
/// 1.3 adds "Explore as guest". The Debug-only button signs in as a seeded test Player.
struct WelcomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Spacer()
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("WhosDown").font(.largeTitle.bold()).foregroundStyle(Color.textPrimary)
                Text("Find people. Play your game.").font(.title3.weight(.semibold)).foregroundStyle(Color.brand)
            }
            Spacer()
            #if DEBUG
            Button("Developer sign-in (Alex, emulator)") {
                Task { await developerSignIn() }
            }
            .buttonStyle(.primary)
            #endif
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(Color.destructive)
            }
        }
        .padding(Spacing.m)
        .background(Color.background)
        #if DEBUG
        .task {
            // Launch with WHOSDOWN_DEV_SIGNIN=1 (scheme env var, or SIMCTL_CHILD_ prefix) to skip the tap.
            if ProcessInfo.processInfo.environment["WHOSDOWN_DEV_SIGNIN"] == "1" { await developerSignIn() }
        }
        #endif
    }

    #if DEBUG
    private func developerSignIn() async {
        do {
            try await environment.auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
        } catch {
            errorMessage = "Sign-in failed. Is the emulator running and seeded? (npm run emulators, npm run seed)"
        }
    }
    #endif
}

#Preview {
    WelcomeView().environment(AppEnvironment.preview(signedInAs: nil))
}
