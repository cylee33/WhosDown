import SwiftUI

/// H10 Player profile (1.22): another Player's public profile. Push it from any screen that shows a
/// Player (H09 Host row, H11 roster rows). Your own ID shows your own profile instead (rule 7).
struct PlayerProfileView: View {
    let userId: String

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                ProfileContent(viewModel: viewModel, showsBioAndStyles: true)
                    .padding(Spacing.m)
                // "Safety & reporting" (H33) is added here by 1.25.
            } else {
                ProgressView().padding(Spacing.xl)
            }
        }
        .background(Color.background)
        .navigationTitle(userId == session.user?.id ? "Profile" : "Player profile")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: userId) {
            let isOwn = userId == session.user?.id
            let viewModel = ProfileViewModel(
                userId: userId, profile: isOwn ? session.profile : nil, users: environment.users,
                reliability: environment.reliability, auth: environment.auth
            )
            self.viewModel = viewModel
            await viewModel.load()
        }
    }
}

#Preview("H10") {
    let environment = AppEnvironment.preview(signedInAs: "seed_jamie")
    NavigationStack {
        PlayerProfileView(userId: "seed_alex")
    }
    .environment(environment)
    .environment(Session(auth: environment.auth, users: environment.users))
}
