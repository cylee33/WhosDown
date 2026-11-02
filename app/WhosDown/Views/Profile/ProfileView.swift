import SwiftUI

/// Phase 0 placeholder for the Profile tab. 1.22 builds the profile (H36); 1.2 owns the real Sign out row.
struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.m) {
                ContentUnavailableView("Profile", systemImage: "person.crop.circle", description: Text("Coming in 1.22"))
                Button("Sign out") { try? environment.auth.signOut() }
                    .buttonStyle(.secondary)
                    .padding(.horizontal, Spacing.m)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView().environment(AppEnvironment.preview())
}
