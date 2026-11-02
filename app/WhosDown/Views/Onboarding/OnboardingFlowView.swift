import SwiftUI

/// Onboarding container. Until 1.4 builds H03 → H42 → H04 → H05 → H44, this shows only the
/// last step's "Find Matches" so new accounts can reach the app.
struct OnboardingFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        VStack(spacing: Spacing.m) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)
            Text("You're all set!").font(.title.bold())
            Spacer()
            if let viewModel {
                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive)
                }
                WorkingButton(title: "Find Matches", isWorking: viewModel.isWorking) {
                    Task { await viewModel.finish() }
                }
            }
        }
        .padding(Spacing.m)
        .background(Color.background)
        .onAppear {
            if viewModel == nil, let userId = session.user?.id {
                viewModel = OnboardingViewModel(userId: userId, users: environment.users)
            }
        }
    }
}
