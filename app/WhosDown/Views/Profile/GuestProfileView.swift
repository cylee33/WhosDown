import SwiftUI

/// The Profile tab for a Guest (1.3, D46): an empty profile with a "+" avatar and sign-in buttons.
struct GuestProfileView: View {
    @Environment(Session.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.m) {
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 96, height: 96)
                    .background(Color.brandSoft, in: .circle)
                    .overlay(Circle().strokeBorder(Color.brand, style: StrokeStyle(lineWidth: 2, dash: [6])))
                    .accessibilityLabel("No profile yet")
                VStack(spacing: Spacing.xs) {
                    Text("You're browsing as a guest").font(.title3.bold()).foregroundStyle(Color.textPrimary)
                    Text("Create an account to set up your profile, sports, and levels.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack(spacing: Spacing.s) {
                    Button("Sign in") { session.showGate(.signIn) }
                        .buttonStyle(.primary)
                    Button("Create account") { session.showGate(.createAccount) }
                        .buttonStyle(.secondary)
                }
            }
            .padding(Spacing.m)
            .background(Color.background)
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    let environment = AppEnvironment.preview(signedInAs: nil)
    GuestProfileView()
        .environment(environment)
        .environment(Session(auth: environment.auth, users: environment.users))
}
