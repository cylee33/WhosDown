import Foundation

/// Onboarding (1.4): H03 sports → H42 levels → H04 profile → H05 permissions → H44 done.
/// Each step saves when the Player continues, and the step reached is remembered on the device,
/// so closing the app resumes at the first unfinished step (rule 8).
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable, Hashable {
        case sports, levels, profile, permissions, done
    }

    // H03 / H42
    var selectedSports: [Sport] = []
    var customSportName = ""
    var levels: [Sport: SkillLevel] = [:]
    // H04
    var playStyles: Set<PlayStyle> = []
    var bio = ""
    var homeArea = ""
    var pickedPhotoData: Data?
    // H05
    var prefs = UserSettings.NotificationPrefs(approvals: true, timeOrLocationChanges: true, cancellations: true)

    /// Steps after `.sports` that are on screen, for a NavigationStack path. Back keeps choices (rule 10).
    var path: [Step] = []
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    private let userId: String
    private let users: UserRepository
    private let permissions: PermissionsService
    private let progress: UserDefaults
    private var profile: UserProfile?

    init(userId: String, profile: UserProfile?, users: UserRepository, permissions: PermissionsService, progress: UserDefaults = .standard) {
        self.userId = userId
        self.users = users
        self.permissions = permissions
        self.progress = progress
        self.profile = profile
        if let profile { prefill(from: profile) }
        let saved = Step(rawValue: progress.integer(forKey: progressKey)) ?? .sports
        path = Step.allCases.filter { $0 != .sports && $0.rawValue <= saved.rawValue }
    }

    var currentStep: Step { path.last ?? .sports }
    var displayName: String { profile?.displayName ?? "" }
    var initials: String { profile?.initials ?? "" }

    // MARK: - Rules

    /// Rule 1 and 2: at least one sport, and a valid name when "Other" is chosen.
    var canContinueFromSports: Bool {
        !selectedSports.isEmpty && (!selectedSports.contains(.other) || ProfileRules.cleanedCustomSportName(customSportName) != nil)
    }

    /// Rule 3: a level for every chosen sport.
    var canContinueFromLevels: Bool {
        selectedSports.allSatisfy { levels[$0] != nil }
    }

    var bioError: String? {
        ProfileRules.fits(bio, limit: ProfileRules.bioLimit) ? nil : "Keep your bio under \(ProfileRules.bioLimit) characters."
    }

    var homeAreaError: String? {
        ProfileRules.fits(homeArea, limit: ProfileRules.homeAreaLimit) ? nil : "Keep this under \(ProfileRules.homeAreaLimit) characters."
    }

    // MARK: - Steps

    func continueFromSports() {
        guard canContinueFromSports else { return }
        for sport in selectedSports where levels[sport] == nil { levels[sport] = .allLevels }
        advance(to: .levels)
    }

    func continueFromLevels() async {
        guard canContinueFromLevels, var fields = currentFields else { return }
        fields.sportLevels = Dictionary(uniqueKeysWithValues: selectedSports.map { ($0.rawValue, levels[$0] ?? .allLevels) })
        fields.customSportName = selectedSports.contains(.other) ? ProfileRules.cleanedCustomSportName(customSportName) : nil
        if await save(fields) { advance(to: .profile) }
    }

    /// H04 "Finish setup": uploads the photo if one was picked, then saves the profile.
    func continueFromProfile() async {
        guard bioError == nil, homeAreaError == nil, var fields = currentFields else { return }
        isWorking = true
        if let data = pickedPhotoData {
            guard let jpeg = AvatarImage.jpegData(from: data) else {
                isWorking = false
                errorMessage = "That photo couldn't be used. Try another one."
                return
            }
            do {
                fields.photoURL = try await users.uploadAvatar(userId: userId, jpegData: jpeg)
            } catch {
                isWorking = false
                errorMessage = "Couldn't upload your photo. Check your connection and try again."
                return
            }
        }
        isWorking = false
        fields.playStyles = PlayStyle.allCases.filter(playStyles.contains)
        fields.bio = ProfileRules.trimmedOrNil(bio)
        fields.homeArea = ProfileRules.trimmedOrNil(homeArea)
        if await save(fields) {
            pickedPhotoData = nil
            advance(to: .permissions)
        }
    }

    func requestLocation() async {
        _ = await permissions.requestLocation()
    }

    /// H05 "Continue": saves the switches, then shows the iOS notification prompt once (rule 7).
    func continueFromPermissions() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await users.saveNotificationPrefs(userId: userId, prefs: prefs)
        } catch {
            errorMessage = Self.saveError
            return
        }
        _ = await permissions.requestNotifications()
        advance(to: .done)
    }

    /// H44 "Find Matches": sets `onboardedAt`; Session then closes onboarding.
    func finish() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await users.completeOnboarding(userId: userId)
            progress.removeObject(forKey: progressKey)
        } catch {
            errorMessage = Self.saveError
        }
    }

    /// One line for H44, e.g. "Soccer · Tennis · Oakland / CMU · Important notifications".
    var summary: String {
        let sports = selectedSports.map { ProfileRules.sportName($0.rawValue, customSportName: ProfileRules.cleanedCustomSportName(customSportName)) }
        let area = ProfileRules.trimmedOrNil(homeArea).map { [$0] } ?? []
        let notifications = prefs.approvals || prefs.timeOrLocationChanges || prefs.cancellations ? ["Important notifications"] : []
        return (sports + area + notifications).joined(separator: " · ")
    }

    // MARK: - Private

    private static let saveError = "Couldn't save. Check your connection and try again."

    private var progressKey: String { "onboardingStep.\(userId)" }

    private var currentFields: ProfileFields? {
        profile.map(ProfileFields.init)
    }

    private func advance(to step: Step) {
        errorMessage = nil
        if !path.contains(step) { path.append(step) }
        if step.rawValue > progress.integer(forKey: progressKey) { progress.set(step.rawValue, forKey: progressKey) }
    }

    private func save(_ fields: ProfileFields) async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            try await users.updateProfile(userId: userId, fields: fields)
            profile = profile.map { apply(fields, to: $0) }
            return true
        } catch {
            errorMessage = Self.saveError
            return false
        }
    }

    private func apply(_ fields: ProfileFields, to profile: UserProfile) -> UserProfile {
        var updated = profile
        updated.photoURL = fields.photoURL
        updated.bio = fields.bio
        updated.homeArea = fields.homeArea
        updated.playStyles = fields.playStyles
        updated.sportLevels = fields.sportLevels
        updated.customSportName = fields.customSportName
        return updated
    }

    private func prefill(from profile: UserProfile) {
        selectedSports = Sport.allCases.filter { profile.sportLevels[$0.rawValue] != nil }
        levels = Dictionary(uniqueKeysWithValues: selectedSports.compactMap { sport in
            profile.sportLevels[sport.rawValue].map { (sport, $0) }
        })
        customSportName = profile.customSportName ?? ""
        playStyles = Set(profile.playStyles)
        bio = profile.bio ?? ""
        homeArea = profile.homeArea ?? ""
    }
}
