#if DEBUG
import Foundation
import UserNotifications

/// Opt-in emulator acceptance only: exercise the real planner, OS delivery and cold-launch delegate.
/// The Match itself is never changed; the shortened time exists only in this device's test request.
enum ReminderDeliveryProbe {
    static func prepare(environment: AppEnvironment, userId: String) async {
        guard let run = ProcessInfo.processInfo.environment["WHOSDOWN_DELIVERY_PROBE"] else { return }
        let key = "delivery-probe-\(run)"
        if UserDefaults.standard.bool(forKey: key) {
            environment.reminders.deliveryProbeReady = true
            return
        }
        do {
            let center = UNUserNotificationCenter.current()
            guard try await center.requestAuthorization(options: [.alert, .sound]) else { return }
            center.removeDeliveredNotifications(withIdentifiers: ["match-m_pickle"])
            guard var match = try await environment.matches.matches(ids: ["m_pickle"]).first else { return }
            match.title = "WhosDown delivery \(run.prefix(6))"
            // Deliver almost immediately so the Simulator does not auto-lock while the UI test waits.
            match.startTime = .now.addingTimeInterval(3610)
            let plan = ReminderPlanner.plan(matches: [match], approvedIds: ["m_pickle"], userId: userId)
            await environment.reminders.sync(plan)
            let pending = await center.pendingNotificationRequests()
            guard pending.contains(where: { $0.identifier == "match-m_pickle" }) else { return }
            UserDefaults.standard.set(true, forKey: key)
            environment.reminders.deliveryProbeReady = true
        } catch {
            environment.reminders.sourceFailed()
        }
    }
}
#endif
