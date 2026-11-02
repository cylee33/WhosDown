import Foundation

/// The nine built-in sports plus "Other" (a Match or Player then also has a custom sport name).
nonisolated enum Sport: String, Codable, CaseIterable, Identifiable, Sendable {
    case soccer, basketball, tennis, volleyball, pickleball, baseball, football, ultimate, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soccer: "Soccer"
        case .basketball: "Basketball"
        case .tennis: "Tennis"
        case .volleyball: "Volleyball"
        case .pickleball: "Pickleball"
        case .baseball: "Baseball"
        case .football: "Football"
        case .ultimate: "Ultimate"
        case .other: "Other"
        }
    }
}

/// A Player's self-chosen level for one sport (GLOSSARY: Skill level).
nonisolated enum SkillLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner, casual, allLevels, intermediate, competitive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .casual: "Casual"
        case .allLevels: "All Levels"
        case .intermediate: "Intermediate"
        case .competitive: "Competitive"
        }
    }
}

nonisolated enum PlayStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case social, competitive, learning

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .social: "Social / casual"
        case .competitive: "Competitive"
        case .learning: "Learning"
        }
    }
}

/// GLOSSARY: Join type.
nonisolated enum JoinType: String, Codable, Sendable {
    case open, approvalRequired
}

/// GLOSSARY: RSVP. A pending RSVP is a Join request.
nonisolated enum RSVPStatus: String, Codable, Sendable {
    case pending, approved, declined, waitlisted, left
}

nonisolated enum MatchStatus: String, Codable, Sendable {
    case scheduled, cancelled
}

/// V1 in-app notification types (1.21, ADR-0008).
nonisolated enum NotificationType: String, Codable, Sendable {
    case approved, declined, matchUpdated, matchCancelled, spotOpened, hostTransferred
}
