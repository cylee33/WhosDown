import Foundation

/// Input checks for creating an account and signing in (1.2). Limits match `firebase/firestore.rules`.
nonisolated enum AccountRules {
    static let minimumPasswordLength = 8
    static let displayNameLimit = 40

    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.trimmingCharacters(in: .whitespaces).split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }

    /// The name as it will be saved, or nil if it's empty or too long.
    static func cleanedDisplayName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...displayNameLimit).contains(trimmed.count) ? trimmed : nil
    }
}
