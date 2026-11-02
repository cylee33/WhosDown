import SwiftUI

/// H01 Welcome (1.2). 1.3 adds "Explore as guest".
struct WelcomeView: View {
    enum Route: Hashable { case createAccount, signIn }

    @Environment(AppEnvironment.self) private var environment
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("WhosDown").font(.largeTitle.bold()).foregroundStyle(Color.textPrimary)
                    Text("Find people. Play your game.").font(.title3.weight(.semibold)).foregroundStyle(Color.brand)
                }
                .padding(.top, Spacing.xl)

                Image(systemName: "soccerball")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))
                    .accessibilityHidden(true)

                Spacer()

                VStack(spacing: Spacing.s) {
                    Button("Create account") { path.append(.createAccount) }
                        .buttonStyle(.primary)
                    Button("Sign in") { path.append(.signIn) }
                        .buttonStyle(.secondary)
                    Text("Guests can browse Matches. Sign in only when you join, post, or message.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    #if DEBUG
                    developerSignIn
                    #endif
                }
            }
            .padding(Spacing.m)
            .background(Color.background)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .createAccount:
                    CreateAccountView(onSignInInstead: { path = [.signIn] })
                case .signIn:
                    SignInView(onCreateAccountInstead: { path = [.createAccount] })
                }
            }
        }
    }

    #if DEBUG
    /// Debug-only shortcut to the seeded test Player. Launch with WHOSDOWN_DEV_SIGNIN=1 to skip the tap.
    private var developerSignIn: some View {
        Button("Developer sign-in (Alex, emulator)") { Task { await signInAsAlex() } }
            .font(.footnote)
            .task {
                if ProcessInfo.processInfo.environment["WHOSDOWN_DEV_SIGNIN"] == "1" { await signInAsAlex() }
            }
    }

    private func signInAsAlex() async {
        try? await environment.auth.signIn(email: "alex@whosdown.test", password: "whosdown123")
    }
    #endif
}

#Preview {
    WelcomeView().environment(AppEnvironment.preview(signedInAs: nil))
}
