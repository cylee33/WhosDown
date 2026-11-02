import Foundation

/// Create Match (1.11): H17 essentials → H18 Venue & details → H19 review → publish → H45.
/// The draft lives as long as the Create tab, so leaving the tab keeps it (rule 9).
@Observable
final class CreateMatchViewModel {
    enum Step: Hashable {
        case location, details, review, created
    }

    var draft = MatchDraft()
    var path: [Step] = []
    /// Field problems show only after the Host tries to continue.
    private(set) var showProblems = false
    private(set) var isPublishing = false
    private(set) var errorMessage: String?
    private(set) var publishedMatchId: String?

    private let matches: MatchRepository

    init(matches: MatchRepository) {
        self.matches = matches
    }

    var problems: [MatchDraft.Problem] { showProblems ? draft.problems() : [] }

    /// H17 "Next: venue & details".
    func continueFromEssentials() {
        showProblems = true
        guard draft.essentialsReady() else { return }
        showProblems = false
        path.append(.details)
    }

    /// H18 "Review Match".
    func continueFromDetails() {
        showProblems = true
        guard draft.problems().isEmpty else { return }
        showProblems = false
        path.append(.review)
    }

    func choose(_ venue: Venue) {
        draft.venue = venue
        if path.last == .location { path.removeLast() }
    }

    /// H19 "Publish Match" (rule 10): one publish at a time; H45 on success.
    func publish(host: UserProfile?) async {
        guard !isPublishing, let host else { return }
        showProblems = true
        guard draft.problems().isEmpty else { return }
        isPublishing = true
        defer { isPublishing = false }
        do {
            publishedMatchId = try await matches.publish(draft, host: host)
            errorMessage = nil
            path.append(.created)
        } catch {
            errorMessage = "Couldn't publish. Check your connection and try again."
        }
    }

    /// After H45: a fresh draft for the next Match.
    func startOver() {
        draft = MatchDraft()
        path = []
        showProblems = false
        publishedMatchId = nil
        errorMessage = nil
    }

    /// "Today · 7:00–8:30 PM", as on H19 and H45.
    var timeText: String {
        let day = Calendar.current.isDateInToday(draft.startTime) ? "Today"
            : Calendar.current.isDateInTomorrow(draft.startTime) ? "Tomorrow"
            : draft.startTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let start = draft.startTime.formatted(date: .omitted, time: .shortened)
        let end = draft.endTime.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(start)–\(end)"
    }
}
