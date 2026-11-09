import PhotosUI
import SwiftUI

/// Onboarding (1.4): H03 → H42 → H04 → H05 → H44, shown full screen over the tab bar until finished.
struct OnboardingFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        Group {
            if let viewModel {
                flow(viewModel)
            } else {
                ProgressView()
            }
        }
        .onChange(of: session.profile, initial: true) {
            // Wait for the profile so earlier answers can be shown again (rule 8).
            if viewModel == nil, let userId = session.user?.id, let profile = session.profile {
                viewModel = OnboardingViewModel(
                    userId: userId, profile: profile, users: environment.users, permissions: environment.permissions
                )
            }
        }
    }

    private func flow(_ viewModel: OnboardingViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return NavigationStack(path: $viewModel.path) {
            SelectSportsView(
                selectedSports: $viewModel.selectedSports,
                customSportName: $viewModel.customSportName,
                canContinue: viewModel.canContinueFromSports,
                onContinue: viewModel.continueFromSports
            )
            .navigationTitle("Select your sports")
            .navigationDestination(for: OnboardingViewModel.Step.self) { step in
                destination(step, viewModel)
            }
        }
        .overlay(alignment: .top) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.onBrand)
                    .padding(Spacing.s)
                    .background(Color.destructive, in: .rect(cornerRadius: Radius.button))
                    .padding(Spacing.s)
            }
        }
    }

    @ViewBuilder
    private func destination(_ step: OnboardingViewModel.Step, _ viewModel: OnboardingViewModel) -> some View {
        @Bindable var viewModel = viewModel
        switch step {
        case .sports:
            EmptyView()
        case .levels:
            SkillLevelsView(
                sports: viewModel.selectedSports,
                customSportName: viewModel.customSportName,
                levels: $viewModel.levels,
                canContinue: viewModel.canContinueFromLevels && !viewModel.isWorking,
                onContinue: { Task { await viewModel.continueFromLevels() } }
            )
            .navigationTitle("Set skill levels")
        case .profile:
            CompleteProfileView(viewModel: viewModel)
                .navigationTitle("Complete profile")
        case .permissions:
            PermissionsView(viewModel: viewModel)
                .navigationTitle("Stay in the loop")
        case .done:
            OnboardingDoneView(viewModel: viewModel)
                .navigationBarBackButtonHidden()
        }
    }
}

/// H04 Complete profile.
struct CompleteProfileView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Spacing.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    HStack(spacing: Spacing.s) {
                        AvatarView(
                            photoURL: nil, initials: viewModel.initials, size: 72,
                            localImage: viewModel.pickedPhotoData.flatMap(UIImage.init(data:))
                        )
                        PhotosPicker(viewModel.pickedPhotoData == nil ? "Add photo" : "Change photo", selection: $photoItem, matching: .images)
                            .font(.subheadline.weight(.semibold))
                    }

                    section("PLAY STYLE") {
                        WrappingHStack {
                            ForEach(PlayStyle.allCases) { style in
                                SelectableChip(title: style.displayName, isSelected: viewModel.playStyles.contains(style)) {
                                    if viewModel.playStyles.contains(style) {
                                        viewModel.playStyles.remove(style)
                                    } else {
                                        viewModel.playStyles.insert(style)
                                    }
                                }
                            }
                        }
                    }

                    LabeledField(label: "BIO", error: viewModel.bioError) {
                        TextField("What should other players know?", text: $viewModel.bio, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(.vertical, Spacing.xs)
                    }

                    LabeledField(label: "HOME AREA", error: viewModel.homeAreaError) {
                        TextField("e.g. Oakland / CMU", text: $viewModel.homeArea)
                    }
                }
                .padding(Spacing.m)
            }
            WorkingButton(title: "Finish setup", isWorking: viewModel.isWorking) {
                Task { await viewModel.continueFromProfile() }
            }
            .padding([.horizontal, .bottom], Spacing.m)
        }
        .background(Color.background)
        .onChange(of: photoItem) { _, item in
            Task { viewModel.pickedPhotoData = try? await item?.loadTransferable(type: Data.self) }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
            content()
        }
    }
}

/// H05 Stay in the loop: location permission and notification preferences.
struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var locationAsked = false
    @State private var requestingLocation = false

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Image(systemName: "location")
                .font(.title)
                .foregroundStyle(Color.brand)
                .frame(width: 72, height: 72)
                .background(Color.brandSoft, in: .circle)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Location").font(.headline).foregroundStyle(Color.textPrimary)
                Text("Show nearby Matches and your selected search radius.")
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            if locationAsked {
                Label("Location choice saved", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.brand)
            } else {
                Button(requestingLocation ? "Requesting location…" : "Allow while using app") {
                    guard !requestingLocation else { return }
                    requestingLocation = true
                    Task {
                        defer { requestingLocation = false }
                        await viewModel.requestLocation()
                        locationAsked = true
                    }
                }
                .buttonStyle(.primary)
                .disabled(requestingLocation)
                Button("Not now") { locationAsked = true }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Notification preferences").font(.headline)
                Text("Important changes only by default").font(.footnote).foregroundStyle(Color.textSecondary)
                WrappingHStack {
                    SelectableChip(title: "Approvals", isSelected: viewModel.prefs.approvals) { viewModel.prefs.approvals.toggle() }
                    SelectableChip(title: "Time/location", isSelected: viewModel.prefs.timeOrLocationChanges) { viewModel.prefs.timeOrLocationChanges.toggle() }
                    SelectableChip(title: "Cancellations", isSelected: viewModel.prefs.cancellations) { viewModel.prefs.cancellations.toggle() }
                }
                Text("You can fine-tune nearby-Match alerts later.").font(.footnote).foregroundStyle(Color.textSecondary)
            }
            .card()

            Spacer()

            WorkingButton(title: "Continue", isWorking: viewModel.isWorking) {
                Task { await viewModel.continueFromPermissions() }
            }
        }
        .padding(Spacing.m)
        }
        .background(Color.background)
    }
}

/// H44 You're all set!
struct OnboardingDoneView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
        VStack(spacing: Spacing.m) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.brand)
                .frame(width: 88, height: 88)
                .background(Color.brandSoft, in: .circle)
            VStack(spacing: Spacing.xs) {
                Text("You're all set!").font(.title.bold()).foregroundStyle(Color.textPrimary)
                Text("Your sports, levels, location, and notification preferences are ready.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("WhosDown is personalized for you").font(.headline)
                Text(viewModel.summary).font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            .card()
            Spacer()
            WorkingButton(title: "Find Matches", isWorking: viewModel.isWorking) {
                Task { await viewModel.finish() }
            }
        }
        .padding(Spacing.m)
        }
        .background(Color.background)
    }
}

#Preview("H04") {
    NavigationStack {
        CompleteProfileView(viewModel: OnboardingViewModel(
            userId: "seed_alex", profile: .sample, users: FakeUserRepository(), permissions: FakePermissionsService(),
            progress: UserDefaults(suiteName: "preview")!
        ))
        .navigationTitle("Complete profile")
    }
}

#Preview("H05") {
    NavigationStack {
        PermissionsView(viewModel: OnboardingViewModel(
            userId: "seed_alex", profile: .sample, users: FakeUserRepository(), permissions: FakePermissionsService(),
            progress: UserDefaults(suiteName: "preview")!
        ))
        .navigationTitle("Stay in the loop")
    }
}
