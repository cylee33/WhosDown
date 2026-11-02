import SwiftUI

/// H02 Create account (1.2).
struct CreateAccountView: View {
    var onSignInInstead: () -> Void

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: CreateAccountViewModel?

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            }
        }
        .background(Color.background)
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel == nil { viewModel = CreateAccountViewModel(auth: environment.auth, users: environment.users) }
        }
    }

    private func form(_ viewModel: CreateAccountViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Takes about 30 seconds.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                LabeledField(label: "Email", error: viewModel.emailError) {
                    TextField("you@example.com", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                LabeledField(
                    label: "Password",
                    hint: "At least \(AccountRules.minimumPasswordLength) characters.",
                    error: viewModel.passwordError
                ) {
                    SecureField("", text: $viewModel.password)
                        .textContentType(.newPassword)
                }
                LabeledField(label: "Display name", error: viewModel.nameError) {
                    TextField("Alex Morgan", text: $viewModel.displayName)
                        .textContentType(.name)
                }

                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.destructive)
                }

                WorkingButton(title: "Continue", isWorking: viewModel.isWorking) {
                    Task { await viewModel.createAccount() }
                }
                .padding(.top, Spacing.xs)

                Button("Already have an account? Sign in", action: onSignInInstead)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .padding(Spacing.m)
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView(onSignInInstead: {})
    }
    .environment(AppEnvironment.preview(signedInAs: nil))
}
