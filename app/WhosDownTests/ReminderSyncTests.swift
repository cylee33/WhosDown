import Foundation
import Testing
@testable import WhosDown

@MainActor
private final class RecordingReminderScheduler: ReminderScheduling {
    let updates = AsyncStream<[MatchReminder]>.makeStream()
    var failed = false
    func sync(_ reminders: [MatchReminder]) async { updates.continuation.yield(reminders) }
    func sourceFailed() { failed = true }
}

@MainActor
struct ReminderSyncTests {
    @Test(.timeLimit(.minutes(1))) func liveApprovalEditsCancellationAndLeaveReconcile() async throws {
        let matchStream = AsyncThrowingStream<Match?, Error>.makeStream()
        let mine = AsyncThrowingStream<[MyRSVP], Error>.makeStream()
        let hosting = AsyncThrowingStream<[Match], Error>.makeStream()
        let matches = FakeMatchRepository()
        matches.matchStream = { _ in matchStream.stream }
        matches.hostedStream = { hosting.stream }
        let rsvps = FakeRSVPRepository()
        rsvps.listStream = { mine.stream }
        let scheduler = RecordingReminderScheduler()
        var updates = scheduler.updates.stream.makeAsyncIterator()
        let model = ReminderSyncModel(matches: matches, rsvps: rsvps, scheduler: scheduler)
        let task = Task { await model.start(userId: "me") }
        defer { task.cancel(); mine.continuation.finish(); hosting.continuation.finish(); matchStream.continuation.finish() }
        var match = Match.sample(startsInHours: 3)
        match.id = "m1"
        match.hostId = "other"
        var rsvp = RSVP.samples[0]
        rsvp.userId = "me"
        rsvp.status = .approved
        hosting.continuation.yield([])
        mine.continuation.yield([MyRSVP(matchId: "m1", rsvp: rsvp)])
        matchStream.continuation.yield(match)
        let approved = await updates.next()
        #expect(approved?.count == 1)
        #expect(approved?.first?.matchId == "m1")
        match.startTime = match.startTime.addingTimeInterval(3600)
        matchStream.continuation.yield(match)
        let edited = await updates.next()
        #expect(edited?.first?.fireDate == match.startTime.addingTimeInterval(-3600))
        match.status = .cancelled
        matchStream.continuation.yield(match)
        #expect(await updates.next() == [])
        rsvp.status = .left
        mine.continuation.yield([MyRSVP(matchId: "m1", rsvp: rsvp)])
        #expect(await updates.next() == [])
    }

    @Test func signedOutClearsReminders() async {
        let scheduler = RecordingReminderScheduler()
        var updates = scheduler.updates.stream.makeAsyncIterator()
        let model = ReminderSyncModel(matches: FakeMatchRepository(), rsvps: FakeRSVPRepository(), scheduler: scheduler)
        await model.start(userId: nil)
        #expect(await updates.next() == [])
    }
}
