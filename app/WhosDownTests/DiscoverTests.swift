import Foundation
import Testing
@testable import WhosDown

/// Phase 3: 1.5 map, 1.6 list, 1.7 filters, 1.8 details, 1.9 weather, 1.10 roster.

/// A fixed Monday noon and a calendar pinned to New York, so time windows don't depend on when tests run.
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}()
private let noon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!

private func match(_ id: String, startsAt hours: Double, length: Double = 1.5, sport: Sport = .soccer,
                   level: SkillLevel = .allLevels, join: JoinType = .open, joined: Int = 3, limit: Int = 10,
                   at location: Coordinate = .cmu, venueId: String = "v_cmu_soccer") -> Match {
    var m = Match.sample(id: id, title: id, startsInHours: 0, joinedCount: joined, playerLimit: limit, joinType: join)
    m.startTime = noon.addingTimeInterval(hours * 3600)
    m.endTime = m.startTime.addingTimeInterval(length * 3600)
    m.sport = sport
    m.skillLevel = level
    m.location = location
    m.venueId = venueId
    return m
}

struct MatchFilterTests {
    @Test func timeWindows() {
        let now = MatchFilter(time: .now)
        #expect(now.includes(match("started", startsAt: -0.5), now: noon, calendar: calendar))
        #expect(now.includes(match("soon", startsAt: 0.9), now: noon, calendar: calendar))
        #expect(!now.includes(match("later", startsAt: 1.5), now: noon, calendar: calendar))

        let tonight = MatchFilter(time: .tonight)
        #expect(!tonight.includes(match("4pm", startsAt: 4), now: noon, calendar: calendar))
        #expect(tonight.includes(match("5pm", startsAt: 5), now: noon, calendar: calendar))
        #expect(tonight.includes(match("11pm", startsAt: 11), now: noon, calendar: calendar))
        #expect(!tonight.includes(match("1am", startsAt: 13), now: noon, calendar: calendar))

        let tomorrow = MatchFilter(time: .tomorrow)
        #expect(tomorrow.includes(match("tomorrow 9am", startsAt: 21), now: noon, calendar: calendar))
        #expect(!tomorrow.includes(match("in two days", startsAt: 48), now: noon, calendar: calendar))
    }

    @Test func customDaysAndTimeOfDay() {
        let wednesday = noon.addingTimeInterval(2 * 86400)
        let filter = MatchFilter(time: .custom(firstDay: wednesday, lastDay: wednesday, fromMinute: 17 * 60, toMinute: 21 * 60))
        #expect(filter.includes(match("wed 6pm", startsAt: 54), now: noon, calendar: calendar))
        #expect(!filter.includes(match("wed 10pm", startsAt: 58), now: noon, calendar: calendar))
        #expect(!filter.includes(match("thu 6pm", startsAt: 78), now: noon, calendar: calendar))
        let anyDayEvenings = MatchFilter(time: .custom(firstDay: nil, lastDay: nil, fromMinute: 17 * 60, toMinute: nil))
        #expect(anyDayEvenings.includes(match("thu 6pm", startsAt: 78), now: noon, calendar: calendar))
    }

    @Test func sportSkillAndJoinType() {
        let filter = MatchFilter(sports: [.soccer], skillLevels: [.beginner], joinType: .open)
        #expect(filter.includes(match("all levels", startsAt: 2, level: .allLevels), now: noon, calendar: calendar))
        #expect(filter.includes(match("beginner", startsAt: 2, level: .beginner), now: noon, calendar: calendar))
        #expect(!filter.includes(match("competitive", startsAt: 2, level: .competitive), now: noon, calendar: calendar))
        #expect(!filter.includes(match("tennis", startsAt: 2, sport: .tennis), now: noon, calendar: calendar))
        #expect(!filter.includes(match("approval", startsAt: 2, join: .approvalRequired), now: noon, calendar: calendar))
        #expect(filter.activeCount == 3)
        #expect(MatchFilter().activeCount == 0)
    }
}

struct MatchFormattingTests {
    @Test func whenAndDetails() {
        #expect(MatchFormatting.when(match("now", startsAt: -0.5), now: noon, calendar: calendar) == "Now")
        #expect(MatchFormatting.when(match("tomorrow", startsAt: 30), now: noon, calendar: calendar).hasPrefix("Tomorrow · "))
        #expect(MatchFormatting.count(match("open", startsAt: 2, joined: 12, limit: 14)) == "12/14")
        #expect(MatchFormatting.count(match("full", startsAt: 2, joined: 14, limit: 14)) == "Full")
        #expect(MatchFormatting.spots(match("open", startsAt: 2, joined: 12, limit: 14)) == "12 / 14 joined · 2 spots left")
        #expect(MatchFormatting.spots(match("one", startsAt: 2, joined: 13, limit: 14)) == "13 / 14 joined · 1 spot left")
        var paid = match("paid", startsAt: 2)
        paid.priceCents = 500
        #expect(MatchFormatting.price(paid) == "$5")
        paid.priceCents = 750
        #expect(MatchFormatting.price(paid) == "$7.50")
    }

    @Test func listPutsNowFirstThenSoonest() {
        let sorted = MatchFormatting.sortedForList([match("later", startsAt: 5), match("now", startsAt: -0.5), match("soon", startsAt: 1)], now: noon)
        #expect(sorted.map(\.title) == ["now", "soon", "later"])
    }
}

struct WeatherTests {
    private func fixture() throws -> Data {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "open-meteo-pittsburgh", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test func parsesHoursUsingTheUTCOffset() throws {
        let hours = try OpenMeteoForecast.hours(from: fixture())
        #expect(hours.count == 48)
        // "2026-11-02T00:00" in Pittsburgh (UTC-5) is 05:00 UTC.
        let utc = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "UTC")!, from: hours[0].time)
        #expect(utc.year == 2026 && utc.month == 11 && utc.day == 2 && utc.hour == 5)
        #expect(hours[0].temperatureF == 52.6)
    }

    @Test func summaryForTheClosestHour() throws {
        let hours = try OpenMeteoForecast.hours(from: fixture())
        let summary = try #require(OpenMeteoForecast.summary(closestTo: hours[0].time.addingTimeInterval(600), in: hours))
        #expect(summary.temperatureF == 53)
        #expect(summary.condition == "Partly cloudy")
        #expect(OpenMeteoForecast.summary(closestTo: hours[0].time.addingTimeInterval(-86400), in: hours) == nil)
    }

    @Test(arguments: [(0, "Clear"), (2, "Partly cloudy"), (3, "Cloudy"), (45, "Fog"), (53, "Drizzle"),
                      (63, "Rain"), (81, "Rain"), (73, "Snow"), (95, "Thunderstorm")])
    func weatherCodes(code: Int, word: String) {
        #expect(OpenMeteoForecast.condition(forWMOCode: code) == word)
    }

    @Test func lineShowsRainOnlyFromTenPercent() {
        #expect(WeatherSummary(temperatureF: 64, condition: "Clear", rainChance: 8).line == "64°F · Clear")
        #expect(WeatherSummary(temperatureF: 64, condition: "Rain", rainChance: 40).line == "64°F · Rain · 40% rain")
    }
}

private final class BundleToken {}

@MainActor
struct DiscoverViewModelTests {
    private let schenley = Coordinate(latitude: 40.4364, longitude: -79.9454)
    private let downtown = Coordinate(latitude: 40.4406, longitude: -79.9959)  // about 2.7 miles from CMU
    private let farAway = Coordinate(latitude: 40.6000, longitude: -80.0000)

    private func makeViewModel(matches: [Match], location: Coordinate? = .cmu, users: FakeUserRepository? = nil,
                               userId: String? = "seed_alex", isGuest: Bool = false) -> (DiscoverViewModel, FakeUserRepository) {
        let users = users ?? FakeUserRepository()
        let viewModel = DiscoverViewModel(
            userId: userId, isGuest: isGuest, matches: FakeMatchRepository(matches: matches),
            rsvps: FakeRSVPRepository(approved: [:], myApproved: ["seed_alex": ["m1"]]),
            users: users, location: FakeLocationService(location: location)
        )
        return (viewModel, users)
    }

    private func upcoming(_ id: String, hours: Double, at location: Coordinate = .cmu, venueId: String = "v1", status: MatchStatus = .scheduled) -> Match {
        var m = Match.sample(id: id, title: id, startsInHours: hours)
        m.location = location
        m.venueId = venueId
        m.status = status
        return m
    }

    @Test func loadsNearbyMatchesWithinTheSavedRadiusAndNextUp() async {
        let users = FakeUserRepository()
        users.savedRadius["seed_alex"] = 2
        let (viewModel, _) = makeViewModel(matches: [
            upcoming("m1", hours: 3), upcoming("near", hours: 1, at: schenley, venueId: "v2"),
            upcoming("downtown", hours: 2, at: downtown, venueId: "v3"), upcoming("far", hours: 2, at: farAway, venueId: "v4"),
            upcoming("cancelled", hours: 2, status: .cancelled),
        ], users: users)
        await viewModel.load()
        #expect(viewModel.radiusMiles == 2)
        #expect(viewModel.visibleMatches.map(\.title) == ["near", "m1"])
        #expect(viewModel.nextUp?.id == "m1")
    }

    @Test func oneSportPinPerVenueWithACount() async {
        let (viewModel, _) = makeViewModel(matches: [upcoming("a", hours: 1), upcoming("b", hours: 2), upcoming("c", hours: 3, at: schenley, venueId: "v2")])
        await viewModel.load()
        #expect(viewModel.pins.map(\.matches.count).sorted() == [1, 2])
    }

    @Test func withoutLocationCentersOnCMU() async {
        let (viewModel, _) = makeViewModel(matches: [], location: nil)
        await viewModel.load()
        #expect(viewModel.userLocation == nil)
        #expect(viewModel.center == .cmu)
        #expect(viewModel.state == .loaded)
    }

    @Test func applyingFiltersSavesOnlyTheDistance() async {
        let (viewModel, users) = makeViewModel(matches: [upcoming("m1", hours: 3), upcoming("downtown", hours: 2, at: downtown, venueId: "v3")])
        await viewModel.load()
        #expect(viewModel.visibleMatches.map(\.title) == ["downtown", "m1"])
        #expect(viewModel.count(with: MatchFilter(), radiusMiles: 1) == 1)

        await viewModel.apply(MatchFilter(sports: [.soccer]), radiusMiles: 1)
        #expect(viewModel.visibleMatches.map(\.title) == ["m1"])
        #expect(users.savedRadius["seed_alex"] == 1)
        #expect(viewModel.filter.activeCount == 1)

        await viewModel.apply(MatchFilter(), radiusMiles: 5)
        #expect(viewModel.visibleMatches.map(\.title) == ["downtown", "m1"])
    }

    @Test func guestsDontSaveTheirDistance() async {
        let (viewModel, users) = makeViewModel(matches: [], userId: "guest_1", isGuest: true)
        await viewModel.load()
        await viewModel.apply(MatchFilter(), radiusMiles: 10)
        #expect(viewModel.radiusMiles == 10)
        #expect(users.savedRadius.isEmpty)
        #expect(viewModel.nextUp == nil)
    }

    @Test func panningFarEnoughSearchesAgain() async {
        let (viewModel, _) = makeViewModel(matches: [upcoming("far", hours: 2, at: farAway, venueId: "v4")])
        await viewModel.load()
        #expect(viewModel.visibleMatches.isEmpty)
        await viewModel.mapSettled(at: Coordinate(latitude: 40.44331, longitude: -79.94361))
        #expect(viewModel.center == .cmu)
        await viewModel.mapSettled(at: farAway)
        #expect(viewModel.visibleMatches.map(\.title) == ["far"])
    }
}

@MainActor
struct MatchDetailAndRosterTests {
    @Test func detailsLoadWithHostReliabilityAndVenueFacts() async {
        var match = Match.samples[0]
        match.fieldReserved = true
        match.reservationWindow = "6:45–8:45 PM"
        let viewModel = MatchDetailViewModel(
            matchId: "m1", userId: "seed_alex", matches: FakeMatchRepository(matches: [match]),
            reliability: FakeReliabilityRepository(records: ["seed_jamie": Reliability(checkedIn: 10, attended: 9)]),
            location: FakeLocationService()
        )
        await viewModel.start()
        #expect(viewModel.match?.title == "Pickup Soccer")
        #expect(viewModel.hostReliability?.label == "90% reliable")
        #expect(viewModel.distance == "0.0 mi")
        #expect(!viewModel.isHost)
        #expect(viewModel.venueFacts == ["Outdoor", "Turf", "Lights on", "Field reserved 6:45–8:45 PM"])
    }

    @Test func missingMatchSaysSo() async {
        let viewModel = MatchDetailViewModel(
            matchId: "gone", userId: "seed_alex", matches: FakeMatchRepository(matches: []),
            reliability: FakeReliabilityRepository(), location: FakeLocationService()
        )
        await viewModel.start()
        #expect(viewModel.state == .missing)
    }

    @Test func rosterListsHostFirstThenByJoinOrderWithReliability() async {
        let viewModel = RosterViewModel(
            match: Match.samples[0], rsvps: FakeRSVPRepository(),
            reliability: FakeReliabilityRepository(records: ["seed_jamie": Reliability(checkedIn: 25, attended: 24)])
        )
        await viewModel.start()
        #expect(viewModel.players.map(\.displayName) == ["Jamie Morales", "Alex Morgan", "Mina Kim"])
        #expect(viewModel.detail(for: viewModel.players[0]) == "Host · 96% reliable")
        #expect(viewModel.detail(for: viewModel.players[2]) == "New player · Intermediate")
        #expect(viewModel.joinedText == "3 / 14 joined")
    }
}
