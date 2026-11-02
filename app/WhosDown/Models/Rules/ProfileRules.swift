import Foundation

/// Limits for profile text (1.4, 1.22). They match `firebase/firestore.rules`.
nonisolated enum ProfileRules {
    static let bioLimit = 300
    static let homeAreaLimit = 60
    static let customSportNameLimit = 30

    /// Trimmed text, or nil when empty: optional fields are saved as null.
    static func trimmedOrNil(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func fits(_ text: String, limit: Int) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count <= limit
    }

    /// The custom "Other" sport name, or nil if empty or too long (1.4 rule 2).
    static func cleanedCustomSportName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...customSportNameLimit).contains(trimmed.count) ? trimmed : nil
    }

    /// H03 rule: at least one sport, and a valid name when "Other" is chosen (1.4 rules 1–2, 1.22 rule 5).
    static func canContinue(sports: [Sport], customSportName: String) -> Bool {
        !sports.isEmpty && (!sports.contains(.other) || cleanedCustomSportName(customSportName) != nil)
    }

    /// The `sportLevels` map saved for the chosen sports; any without a level gets All Levels.
    static func sportLevels(for sports: [Sport], levels: [Sport: SkillLevel]) -> [String: SkillLevel] {
        Dictionary(uniqueKeysWithValues: sports.map { ($0.rawValue, levels[$0] ?? .allLevels) })
    }

    /// The chosen sports and their levels from a saved profile, in the order of `Sport.allCases`.
    static func selection(from profile: UserProfile) -> (sports: [Sport], levels: [Sport: SkillLevel]) {
        let sports = Sport.allCases.filter { profile.sportLevels[$0.rawValue] != nil }
        let levels = Dictionary(uniqueKeysWithValues: sports.compactMap { sport in
            profile.sportLevels[sport.rawValue].map { (sport, $0) }
        })
        return (sports, levels)
    }

    /// One row per sport with its level, for H36/H10 ("organized by sport", 1.22 rule 2).
    static func sportRows(_ profile: UserProfile) -> [(sport: String, level: String)] {
        selection(from: profile).sports.map { sport in
            (sportName(sport.rawValue, customSportName: profile.customSportName),
             profile.sportLevels[sport.rawValue]?.displayName ?? SkillLevel.allLevels.displayName)
        }
    }

    /// Line under the name, e.g. "Soccer · Tennis · Social / casual".
    static func subtitle(_ profile: UserProfile) -> String {
        let sports = selection(from: profile).sports.map { sportName($0.rawValue, customSportName: profile.customSportName) }
        let styles = PlayStyle.allCases.filter(profile.playStyles.contains).map(\.displayName)
        return (sports + styles).joined(separator: " · ")
    }

    /// Display name of a sport key in `sportLevels` ("other" uses the Player's custom name).
    static func sportName(_ key: String, customSportName: String?) -> String {
        guard let sport = Sport(rawValue: key) else { return key.capitalized }
        return sport == .other ? (customSportName ?? sport.displayName) : sport.displayName
    }
}
