import Foundation

/// Everything a Host fills in on H17–H18 before publishing (1.11). Limits match `firebase/firestore.rules`.
nonisolated struct MatchDraft: Equatable, Sendable {
    static let titleLimit = 40
    static let playerLimitRange = 2...50
    static let maxPriceDollars = 100
    static let maxLength: TimeInterval = 6 * 3600
    static let notesLimit = 500
    static let facilityNoteLimit = 200
    static let reservationWindowLimit = 40

    var sport: Sport?
    var customSportName = ""
    var title = ""
    var startTime: Date
    var endTime: Date
    var venue: Venue?
    var skillLevel: SkillLevel = .allLevels
    var playerLimit = 10
    var waitlistEnabled = true
    var joinType: JoinType = .open
    var isPaid = false
    var priceDollars = 0
    var fieldReserved = false
    var reservationWindow = ""
    var facilityNote = ""
    var notes = ""

    /// Defaults (rule 2): starts at the next full hour, lasts 90 minutes.
    init(now: Date = .now, calendar: Calendar = .current) {
        let nextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? now
        startTime = nextHour
        endTime = nextHour.addingTimeInterval(90 * 60)
    }

    /// Problems that block publishing, in the order they appear on screen. Empty means ready.
    func problems(now: Date = .now) -> [Problem] {
        var problems: [Problem] = []
        if sport == nil { problems.append(.noSport) }
        if sport == .other && ProfileRules.cleanedCustomSportName(customSportName) == nil { problems.append(.customSportName) }
        if title.trimmingCharacters(in: .whitespaces).count > Self.titleLimit { problems.append(.titleTooLong) }
        if startTime <= now { problems.append(.startInPast) }
        if endTime <= startTime { problems.append(.endBeforeStart) }
        else if endTime.timeIntervalSince(startTime) > Self.maxLength { problems.append(.tooLong) }
        if venue == nil { problems.append(.noLocation) }
        if !Self.playerLimitRange.contains(playerLimit) { problems.append(.playerLimit) }
        if isPaid && !(1...Self.maxPriceDollars).contains(priceDollars) { problems.append(.price) }
        if notes.count > Self.notesLimit || facilityNote.count > Self.facilityNoteLimit
            || reservationWindow.count > Self.reservationWindowLimit { problems.append(.textTooLong) }
        return problems
    }

    /// The essentials on H17 are complete (rule 1); "Next" is enabled.
    func essentialsReady(now: Date = .now) -> Bool {
        problems(now: now).allSatisfy { $0 == .textTooLong }
    }

    /// Rule 6: empty title means "Pickup {Sport}".
    var resolvedTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        return "Pickup \(sportName)"
    }

    var sportName: String {
        guard let sport else { return "Match" }
        return sport == .other ? (ProfileRules.cleanedCustomSportName(customSportName) ?? Sport.other.displayName) : sport.displayName
    }

    var priceCents: Int { isPaid ? priceDollars * 100 : 0 }

    var priceText: String { isPaid ? "$\(priceDollars)" : "Free" }

    enum Problem: Hashable {
        case noSport, customSportName, titleTooLong, startInPast, endBeforeStart, tooLong, noLocation, playerLimit, price, textTooLong

        var message: String {
            switch self {
            case .noSport: "Choose a sport."
            case .customSportName: "Name your activity (up to 30 characters)."
            case .titleTooLong: "Keep the title under \(MatchDraft.titleLimit) characters."
            case .startInPast: "Pick a start time in the future."
            case .endBeforeStart: "The end time must be after the start."
            case .tooLong: "A Match can last up to 6 hours."
            case .noLocation: "Choose a location."
            case .playerLimit: "Player limit must be 2–50, including you."
            case .price: "Enter a price from $1 to $100, or choose Free."
            case .textTooLong: "One of the notes is too long."
            }
        }
    }
}
