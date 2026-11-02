import PhotosUI
import SwiftUI

/// The Profile tab: H36 own profile, with H49 Edit and the Sports & levels edit (1.22).
struct ProfileView: View {
    enum Route: Hashable {
        case edit
        /// H03 then H42; `saveOnDone` is true from H36 (save right away) and false from H49 (saved with "Save profile").
        case sports(saveOnDone: Bool)
        case levels(saveOnDone: Bool)
    }

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: ProfileViewModel?
    @State private var editViewModel: EditProfileViewModel?
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let viewModel {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            ProfileContent(viewModel: viewModel)
                            preferences(viewModel)
                        }
                        .padding(Spacing.m)
                    }
                } else {
                    ProgressView()
                }
            }
            .background(Color.background)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { startEditing(.edit) }
                        .disabled(session.profile == nil)
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
        }
        .task(id: session.user?.id) {
            guard let userId = session.user?.id else { return }
            let viewModel = ProfileViewModel(
                userId: userId, profile: session.profile, users: environment.users,
                reliability: environment.reliability, auth: environment.auth
            )
            self.viewModel = viewModel
            await viewModel.load()
        }
        .onChange(of: session.profile) { _, profile in viewModel?.update(profile) }
    }

    private func preferences(_ viewModel: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("PREFERENCES").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
            Button { startEditing(.sports(saveOnDone: true)) } label: {
                SettingsRow(title: "Sports & levels", detail: viewModel.sportRows.map(\.sport).joined(separator: " · "))
            }
            .buttonStyle(.plain)
            Button(role: .destructive) { viewModel.signOut() } label: {
                Text("Sign out")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.s)
        }
    }

    private func startEditing(_ route: Route) {
        guard let userId = session.user?.id, let profile = session.profile else { return }
        editViewModel = EditProfileViewModel(userId: userId, profile: profile, users: environment.users)
        path = [route]
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        if let editViewModel {
            @Bindable var edit = editViewModel
            switch route {
            case .edit:
                EditProfileView(viewModel: editViewModel, onEditSports: { path.append(.sports(saveOnDone: false)) }) {
                    Task { if await editViewModel.save() { path = [] } }
                }
            case .sports(let saveOnDone):
                SelectSportsView(
                    selectedSports: $edit.selectedSports,
                    customSportName: $edit.customSportName,
                    canContinue: edit.canContinueFromSports,
                    onContinue: {
                        edit.continueFromSports()
                        path.append(.levels(saveOnDone: saveOnDone))
                    }
                )
                .navigationTitle("Select your sports")
            case .levels(let saveOnDone):
                SkillLevelsView(
                    sports: edit.selectedSports,
                    customSportName: edit.customSportName,
                    levels: $edit.levels,
                    buttonTitle: saveOnDone ? "Save" : "Done",
                    canContinue: edit.canContinueFromLevels && !edit.isWorking,
                    onContinue: {
                        if saveOnDone {
                            Task { if await editViewModel.save() { path = [] } }
                        } else {
                            path.removeLast(2)
                        }
                    }
                )
                .navigationTitle("Set skill levels")
                .overlay(alignment: .top) { ErrorBanner(message: edit.errorMessage) }
            }
        }
    }
}

/// The body of a profile, shared by H36 (own) and H10 (another Player).
struct ProfileContent: View {
    let viewModel: ProfileViewModel
    var showsBioAndStyles = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let profile = viewModel.profile {
                HStack(spacing: Spacing.s) {
                    AvatarView(photoURL: profile.photoURL, initials: profile.initials, size: 72)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(profile.displayName).font(.title2.bold()).foregroundStyle(Color.textPrimary)
                        if !viewModel.subtitle.isEmpty {
                            Text(viewModel.subtitle).font(.subheadline).foregroundStyle(Color.textSecondary)
                        }
                        if let played = viewModel.matchesPlayedLine {
                            Text(played).font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                if !viewModel.sportRows.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("SPORTS & LEVELS").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                        ForEach(viewModel.sportRows, id: \.sport) { row in
                            HStack {
                                Text(row.sport).foregroundStyle(Color.textPrimary)
                                Spacer()
                                Chip(text: row.level)
                            }
                        }
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Attendance reliability").font(.subheadline).foregroundStyle(Color.textSecondary)
                    if let reliability = viewModel.reliability {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(reliability.percent.map { "\($0)%" } ?? "New player")
                                .font(.title.bold())
                                .foregroundStyle(Color.brand)
                            if let line = viewModel.attendanceLine {
                                Text(line).font(.footnote).foregroundStyle(Color.textSecondary)
                            }
                        }
                        Text("Reliability reflects attendance, not playing skill.")
                            .font(.footnote).foregroundStyle(Color.textSecondary)
                    } else {
                        ProgressView()
                    }
                }
                .card()

                if showsBioAndStyles {
                    if !profile.playStyles.isEmpty {
                        WrappingHStack {
                            ForEach(PlayStyle.allCases.filter(profile.playStyles.contains)) { style in
                                Chip(text: style.displayName)
                            }
                        }
                    }
                    if let bio = profile.bio {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("BIO").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                            Text(bio).foregroundStyle(Color.textPrimary)
                        }
                    }
                }
            }
            if let message = viewModel.errorMessage {
                Text(message).font(.footnote).foregroundStyle(Color.destructive)
            }
        }
    }
}

/// A tappable row with a title, a one-line detail, and a chevron (H36 preferences).
struct SettingsRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                if !detail.isEmpty {
                    Text(detail).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.textSecondary)
        }
        .card()
    }
}

/// A red message pinned to the top of a screen.
struct ErrorBanner: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(Spacing.s)
                .background(Color.destructive, in: .rect(cornerRadius: Radius.button))
                .padding(Spacing.s)
        }
    }
}

/// H49 Edit profile.
struct EditProfileView: View {
    @Bindable var viewModel: EditProfileViewModel
    let onEditSports: () -> Void
    let onSave: () -> Void
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Spacing.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    HStack(spacing: Spacing.s) {
                        AvatarView(
                            photoURL: viewModel.photoURL, initials: viewModel.initials, size: 72,
                            localImage: viewModel.pickedPhotoData.flatMap(UIImage.init(data:))
                        )
                        PhotosPicker("Change photo", selection: $photoItem, matching: .images)
                            .font(.subheadline.weight(.semibold))
                    }
                    LabeledField(label: "DISPLAY NAME", error: viewModel.nameError) {
                        TextField("", text: $viewModel.displayName).textContentType(.name)
                    }
                    LabeledField(label: "HOME AREA", error: viewModel.homeAreaError) {
                        TextField("e.g. Oakland / CMU", text: $viewModel.homeArea)
                    }
                    LabeledField(label: "BIO", error: viewModel.bioError) {
                        TextField("What should other players know?", text: $viewModel.bio, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(.vertical, Spacing.xs)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("SPORTS & LEVELS").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                        Button(action: onEditSports) {
                            HStack {
                                Text(viewModel.sportsSummary).foregroundStyle(Color.textPrimary).multilineTextAlignment(.leading)
                                Spacer()
                                Text("Edit").font(.subheadline.weight(.semibold)).foregroundStyle(Color.brand)
                            }
                            .card()
                        }
                        .buttonStyle(.plain)
                    }
                    if let message = viewModel.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }
                }
                .padding(Spacing.m)
            }
            WorkingButton(title: "Save profile", isWorking: viewModel.isWorking, isEnabled: viewModel.canSave, action: onSave)
                .padding([.horizontal, .bottom], Spacing.m)
        }
        .background(Color.background)
        .navigationTitle("Edit profile")
        .onChange(of: photoItem) { _, item in
            Task { viewModel.pickedPhotoData = try? await item?.loadTransferable(type: Data.self) }
        }
    }
}

#Preview("H36") {
    let environment = AppEnvironment.preview()
    ProfileView()
        .environment(environment)
        .environment(Session(auth: environment.auth, users: environment.users))
}

#Preview("H49") {
    NavigationStack {
        EditProfileView(
            viewModel: EditProfileViewModel(userId: "seed_alex", profile: .sample, users: FakeUserRepository()),
            onEditSports: {}, onSave: {}
        )
    }
}
