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

    /// Display name of a sport key in `sportLevels` ("other" uses the Player's custom name).
    static func sportName(_ key: String, customSportName: String?) -> String {
        guard let sport = Sport(rawValue: key) else { return key.capitalized }
        return sport == .other ? (customSportName ?? sport.displayName) : sport.displayName
    }
}
