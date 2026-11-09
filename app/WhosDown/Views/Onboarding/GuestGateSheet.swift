import SwiftUI

/// H34 Guest join gate (1.3): opens over whatever the Guest was looking at, and closes itself
/// once they have an account, leaving them on the same screen.
struct GuestGateSheet: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(Session.self) private var session
    @State private var path: [Session.GateRoute] = []
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Sign in to join").font(.title2.bold()).foregroundStyle(Color.textPrimary)
                    Text("Guests can browse everything.").font(.subheadline.weight(.semibold)).foregroundStyle(Color.textPrimary)
                    Text("Create an account or sign in only when you're ready to join, host, post, or message.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                Button("Create account") { path = [.createAccount] }
                    .buttonStyle(.primary)
                Button("Sign in") { path = [.signIn] }
                    .buttonStyle(.secondary)
                Button("Keep browsing") { session.gateRoute = nil }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .padding(Spacing.m)
            }
            .background(Color.background)
            .navigationDestination(for: Session.GateRoute.self) { route in
                AccountFormView(route: route, onSwitch: { path = [$0] })
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .onChange(of: path) { _, newPath in detent = newPath.isEmpty && !dynamicTypeSize.isAccessibilitySize ? .medium : .large }
        .onAppear {
            if dynamicTypeSize.isAccessibilitySize { detent = .large }
            if let route = session.gateRoute, route != .choose { path = [route] }
        }
    }
}

/// What a Guest sees on tabs that need an account (1.3): Matches and Create.
struct GuestPromptView: View {
    let title: String
    let message: String
    let systemImage: String

    @Environment(Session.self) private var session

    var body: some View {
        VStack(spacing: Spacing.m) {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
            VStack(spacing: Spacing.s) {
                Button("Create account") { session.showGate(.createAccount) }
                    .buttonStyle(.primary)
                Button("Sign in") { session.showGate(.signIn) }
                    .buttonStyle(.secondary)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.background)
    }
}

#Preview("Gate") {
    let environment = AppEnvironment.preview(signedInAs: nil)
    Color.background.sheet(isPresented: .constant(true)) {
        GuestGateSheet()
    }
    .environment(environment)
    .environment(Session(auth: environment.auth, users: environment.users))
}
