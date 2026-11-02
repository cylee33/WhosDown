import SwiftUI

/// H41 Sign in (1.2).
struct SignInView: View {
    var onCreateAccountInstead: () -> Void

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: SignInViewModel?

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            }
        }
        .background(Color.background)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil { viewModel = SignInViewModel(auth: environment.auth) }
        }
    }

    private func form(_ viewModel: SignInViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Welcome back").font(.title.bold()).foregroundStyle(Color.textPrimary)
                    Text("Sign in to join Matches and message players.")
                        .font(.subheadline).foregroundStyle(Color.textSecondary)
                }

                LabeledField(label: "EMAIL") {
                    TextField("you@example.com", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    LabeledField(label: "PASSWORD") {
                        SecureField("", text: $viewModel.password)
                            .textContentType(.password)
                    }
                    Button("Forgot password?") { Task { await viewModel.sendPasswordReset() } }
                        .font(.footnote)
                        .disabled(viewModel.isWorking)
                }

                Text("Your email is private. Other players only see your public profile.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.info.opacity(0.08), in: .rect(cornerRadius: Radius.button))

                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive)
                }
                if let message = viewModel.resetMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.brand)
                }

                WorkingButton(title: "Sign in", isWorking: viewModel.isWorking) {
                    Task { await viewModel.signIn() }
                }

                Button("New here? Create account", action: onCreateAccountInstead)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .padding(Spacing.m)
        }
    }
}

#Preview {
    NavigationStack {
        SignInView(onCreateAccountInstead: {})
    }
    .environment(AppEnvironment.preview(signedInAs: nil))
}
