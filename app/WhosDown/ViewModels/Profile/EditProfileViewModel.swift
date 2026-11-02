import Foundation

/// H49 Edit profile, and the "Sports & levels" edit (H03 → H42) from H36 (1.22).
@Observable
final class EditProfileViewModel {
    var displayName: String
    var homeArea: String
    var bio: String
    var selectedSports: [Sport]
    var customSportName: String
    var levels: [Sport: SkillLevel]
    var pickedPhotoData: Data?
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    private let userId: String
    private let original: UserProfile
    private let users: UserRepository

    init(userId: String, profile: UserProfile, users: UserRepository) {
        self.userId = userId
        self.original = profile
        self.users = users
        displayName = profile.displayName
        homeArea = profile.homeArea ?? ""
        bio = profile.bio ?? ""
        customSportName = profile.customSportName ?? ""
        (selectedSports, levels) = ProfileRules.selection(from: profile)
    }

    var photoURL: String? { original.photoURL }
    var initials: String { original.initials }

    var nameError: String? {
        AccountRules.cleanedDisplayName(displayName) == nil ? "Enter a name of up to \(AccountRules.displayNameLimit) characters." : nil
    }

    var bioError: String? {
        ProfileRules.fits(bio, limit: ProfileRules.bioLimit) ? nil : "Keep your bio under \(ProfileRules.bioLimit) characters."
    }

    var homeAreaError: String? {
        ProfileRules.fits(homeArea, limit: ProfileRules.homeAreaLimit) ? nil : "Keep this under \(ProfileRules.homeAreaLimit) characters."
    }

    /// Rule 5: at least one sport, and a name for "Other".
    var canContinueFromSports: Bool {
        ProfileRules.canContinue(sports: selectedSports, customSportName: customSportName)
    }

    var canContinueFromLevels: Bool {
        selectedSports.allSatisfy { levels[$0] != nil }
    }

    func continueFromSports() {
        for sport in selectedSports where levels[sport] == nil { levels[sport] = .allLevels }
    }

    /// "Soccer · All Levels, Tennis · Casual" for the H49 row.
    var sportsSummary: String {
        selectedSports
            .map { "\(ProfileRules.sportName($0.rawValue, customSportName: customSportName)) · \((levels[$0] ?? .allLevels).displayName)" }
            .joined(separator: ", ")
    }

    /// Rule 4: Save is disabled until something changed and everything is valid.
    var canSave: Bool {
        !isWorking && nameError == nil && bioError == nil && homeAreaError == nil
            && canContinueFromSports && (pickedPhotoData != nil || fields != ProfileFields(original))
    }

    /// Saves the photo (if picked) and every field. Returns true on success.
    func save() async -> Bool {
        guard canSave else { return false }
        isWorking = true
        defer { isWorking = false }
        var fields = fields
        do {
            if let data = pickedPhotoData {
                guard let jpeg = AvatarImage.jpegData(from: data) else {
                    errorMessage = "That photo couldn't be used. Try another one."
                    return false
                }
                fields.photoURL = try await users.uploadAvatar(userId: userId, jpegData: jpeg)
            }
            try await users.updateProfile(userId: userId, fields: fields)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn't save. Check your connection and try again."
            return false
        }
    }

    private var fields: ProfileFields {
        var fields = ProfileFields(original)
        fields.displayName = AccountRules.cleanedDisplayName(displayName) ?? displayName
        fields.homeArea = ProfileRules.trimmedOrNil(homeArea)
        fields.bio = ProfileRules.trimmedOrNil(bio)
        fields.sportLevels = ProfileRules.sportLevels(for: selectedSports, levels: levels)
        fields.customSportName = selectedSports.contains(.other) ? ProfileRules.cleanedCustomSportName(customSportName) : nil
        return fields
    }
}
