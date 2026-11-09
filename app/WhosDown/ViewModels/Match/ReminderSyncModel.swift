import Foundation

/// Lives above the tabs, so changes sync even when My Matches is not open.
@Observable
final class ReminderSyncModel {
    private let matches: MatchRepository
    private let rsvps: RSVPRepository
    private let scheduler: any ReminderScheduling
    private var approvedIds = Set<String>()
    private var hosted: [Match] = []
    private var joined: [String: Match] = [:]
    private var loadedIds = Set<String>()
    private var watchTask: Task<Void, Never>?
    private var generation = 0
    private var loadedRSVPs = false
    private var loadedHosted = false

    init(matches: MatchRepository, rsvps: RSVPRepository, scheduler: any ReminderScheduling) {
        self.matches = matches
        self.rsvps = rsvps
        self.scheduler = scheduler
    }

    func start(userId: String?) async {
        defer { watchTask?.cancel() }
        guard let userId else { await scheduler.sync([]); return }
        async let mine: Void = listenRSVPs(userId)
        async let hosting: Void = listenHosted(userId)
        _ = await (mine, hosting)
    }

    private func listenRSVPs(_ userId: String) async {
        do {
            for try await values in rsvps.myRSVPListChanges(userId: userId) {
                guard !Task.isCancelled else { return }
                let ids = Set(values.filter { $0.rsvp.status == .approved }.map(\.matchId))
                let changed = ids != approvedIds
                loadedRSVPs = true
                if !changed { await sync(userId); continue }
                approvedIds = ids
                loadedIds.formIntersection(ids)
                joined = joined.filter { ids.contains($0.key) }
                generation += 1
                let currentGeneration = generation
                watchTask?.cancel()
                await sync(userId)
                watchTask = Task {
                    await withTaskGroup(of: Void.self) { group in
                        for id in ids {
                            group.addTask { await self.watch(id, userId: userId, generation: currentGeneration) }
                        }
                    }
                }
            }
        } catch {
            if !Task.isCancelled { scheduler.sourceFailed() }
        }
    }

    private func watch(_ id: String, userId: String, generation: Int) async {
        do {
            for try await match in matches.matchChanges(matchId: id) {
                guard !Task.isCancelled, generation == self.generation else { return }
                loadedIds.insert(id)
                joined[id] = match
                await sync(userId)
            }
        } catch {
            if !Task.isCancelled { scheduler.sourceFailed() }
        }
    }

    private func listenHosted(_ userId: String) async {
        do {
            for try await value in matches.hostedChanges(hostId: userId) {
                guard !Task.isCancelled else { return }
                loadedHosted = true
                hosted = value
                await sync(userId)
            }
        } catch {
            if !Task.isCancelled { scheduler.sourceFailed() }
        }
    }

    private func sync(_ userId: String) async {
        guard !Task.isCancelled, loadedRSVPs, loadedHosted, approvedIds.isSubset(of: loadedIds) else { return }
        // The individual listener is authoritative when an edited/cancelled hosted Match is also in the RSVP list.
        var combined = Dictionary(uniqueKeysWithValues: hosted.compactMap { match in match.id.map { ($0, match) } })
        combined.merge(joined) { _, latest in latest }
        await scheduler.sync(ReminderPlanner.plan(matches: Array(combined.values), approvedIds: approvedIds, userId: userId))
    }
}
