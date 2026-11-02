import Foundation
import Testing
@testable import WhosDown

/// 1.11 Create Match.
struct MatchDraftTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000) // a fixed "now"

    private func ready() -> MatchDraft {
        var draft = MatchDraft(now: now)
        draft.sport = .soccer
        draft.venue = Venue.samples[0]
        return draft
    }

    @Test func defaultsToNextFullHourForNinetyMinutes() {
        let draft = MatchDraft(now: now)
        #expect(Calendar.current.component(.minute, from: draft.startTime) == 0)
        #expect(draft.startTime > now)
        #expect(draft.startTime.timeIntervalSince(now) <= 3600)
        #expect(draft.endTime.timeIntervalSince(draft.startTime) == 5400)
        #expect(draft.waitlistEnabled)
        #expect(draft.joinType == .open)
    }

    @Test func requiresSportAndLocation() {
        let empty = MatchDraft(now: now)
        #expect(empty.problems(now: now) == [.noSport, .noLocation])
        #expect(ready().problems(now: now).isEmpty)
    }

    @Test func timesMustBeFutureOrderedAndAtMostSixHours() {
        var draft = ready()
        draft.startTime = now.addingTimeInterval(-60)
        #expect(draft.problems(now: now).contains(.startInPast))
        draft = ready()
        draft.endTime = draft.startTime
        #expect(draft.problems(now: now) == [.endBeforeStart])
        draft.endTime = draft.startTime.addingTimeInterval(6 * 3600 + 60)
        #expect(draft.problems(now: now) == [.tooLong])
        draft.endTime = draft.startTime.addingTimeInterval(6 * 3600)
        #expect(draft.problems(now: now).isEmpty)
    }

    @Test func limitsAndPrice() {
        var draft = ready()
        draft.playerLimit = 1
        #expect(draft.problems(now: now) == [.playerLimit])
        draft.playerLimit = 50
        draft.isPaid = true
        draft.priceDollars = 0
        #expect(draft.problems(now: now) == [.price])
        draft.priceDollars = 101
        #expect(draft.problems(now: now) == [.price])
        draft.priceDollars = 5
        #expect(draft.problems(now: now).isEmpty)
        #expect(draft.priceCents == 500)
        #expect(draft.priceText == "$5")
    }

    @Test func titleDefaultsToPickupSportAndCustomSportNeedsAName() {
        var draft = ready()
        #expect(draft.resolvedTitle == "Pickup Soccer")
        draft.title = "  7v7 at Schenley "
        #expect(draft.resolvedTitle == "7v7 at Schenley")
        draft.title = ""
        draft.sport = .other
        #expect(draft.problems(now: now) == [.customSportName])
        draft.customSportName = "Spikeball"
        #expect(draft.resolvedTitle == "Pickup Spikeball")
        draft.title = String(repeating: "x", count: 41)
        #expect(draft.problems(now: now) == [.titleTooLong])
    }
}

@MainActor
struct CreateMatchViewModelTests {
    private func readyViewModel(_ matches: FakeMatchRepository) -> CreateMatchViewModel {
        let viewModel = CreateMatchViewModel(matches: matches)
        viewModel.draft.sport = .soccer
        viewModel.draft.startTime = .now.addingTimeInterval(3600)
        viewModel.draft.endTime = .now.addingTimeInterval(3600 + 5400)
        return viewModel
    }

    @Test func nextShowsProblemsUntilEssentialsAreComplete() {
        let viewModel = readyViewModel(FakeMatchRepository())
        viewModel.continueFromEssentials()
        #expect(viewModel.problems == [.noLocation])
        #expect(viewModel.path.isEmpty)

        viewModel.path.append(.location)
        viewModel.choose(Venue.samples[0])
        #expect(viewModel.path.isEmpty)
        viewModel.continueFromEssentials()
        #expect(viewModel.path == [.details])
        #expect(viewModel.problems.isEmpty)
    }

    @Test func publishWritesOnceAndShowsCreated() async {
        let matches = FakeMatchRepository()
        let viewModel = readyViewModel(matches)
        viewModel.draft.venue = Venue.samples[0]
        viewModel.path = [.details, .review]
        await viewModel.publish(host: .sample)
        #expect(matches.published.count == 1)
        #expect(matches.published.first?.hostId == "seed_alex")
        #expect(viewModel.path.last == .created)
        #expect(viewModel.publishedMatchId == "m_published_1")

        viewModel.startOver()
        #expect(viewModel.path.isEmpty)
        #expect(viewModel.draft.sport == nil)
    }

    @Test func publishFailureShowsAMessageAndStays() async {
        let matches = FakeMatchRepository(error: URLError(.notConnectedToInternet))
        let viewModel = readyViewModel(matches)
        viewModel.draft.venue = Venue.samples[0]
        viewModel.path = [.details, .review]
        await viewModel.publish(host: .sample)
        #expect(viewModel.errorMessage == "Couldn't publish. Check your connection and try again.")
        #expect(viewModel.path.last == .review)
    }

    @Test func leavingAndComingBackKeepsTheDraft() {
        let viewModel = readyViewModel(FakeMatchRepository())
        viewModel.draft.title = "Sunday 7v7"
        viewModel.path = [.details]
        viewModel.path.removeLast()
        #expect(viewModel.draft.title == "Sunday 7v7")
    }
}
