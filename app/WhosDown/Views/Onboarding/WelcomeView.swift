import SwiftUI

/// H01 Welcome (1.2, 1.3).
struct WelcomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var path: [Session.GateRoute] = []
    @State private var viewModel: WelcomeViewModel?

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
                    Button("Explore as guest") { Task { await viewModel?.exploreAsGuest() } }
                        .font(.subheadline.weight(.semibold))
                        .disabled(viewModel?.isWorking ?? true)
                    Text("Guests can browse Matches. Sign in only when you join, post, or message.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    if let message = viewModel?.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                    #if DEBUG
                    Button("Developer sign-in (Alex, emulator)") { Task { await viewModel?.developerSignIn() } }
                        .font(.footnote)
                    #endif
                }
            }
            .padding(Spacing.m)
            .background(Color.background)
            .navigationDestination(for: Session.GateRoute.self) { route in
                AccountFormView(route: route, onSwitch: { path = [$0] })
            }
        }
        .task {
            if viewModel == nil { viewModel = WelcomeViewModel(auth: environment.auth) }
            #if DEBUG
            // Launch with WHOSDOWN_DEV_SIGNIN=1 (Alex) or =guest (Guest) to skip the tap.
            switch ProcessInfo.processInfo.environment["WHOSDOWN_DEV_SIGNIN"] {
            case "1": await viewModel?.developerSignIn()
            case "guest": await viewModel?.exploreAsGuest()
            default: break
            }
            #endif
        }
    }
}

/// H02 or H41, with a link to switch to the other. Used by H01 and by the Guest gate (H34).
struct AccountFormView: View {
    let route: Session.GateRoute
    let onSwitch: (Session.GateRoute) -> Void

    var body: some View {
        switch route {
        case .createAccount, .choose:
            CreateAccountView(onSignInInstead: { onSwitch(.signIn) })
        case .signIn:
            SignInView(onCreateAccountInstead: { onSwitch(.createAccount) })
        }
    }
}

#Preview {
    WelcomeView().environment(AppEnvironment.preview(signedInAs: nil))
}
