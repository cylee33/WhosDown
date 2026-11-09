import Foundation
import UserNotifications

protocol ReminderScheduling {
    func sync(_ reminders: [MatchReminder]) async
    func sourceFailed()
}

/// The notification service boundary keeps denial, replacement and retry behavior testable.
protocol ReminderNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePending(identifiers: [String])
}

final class SystemReminderNotificationCenter: ReminderNotificationCenter {
    private let center: UNUserNotificationCenter
    init(center: UNUserNotificationCenter) { self.center = center }
    func authorizationStatus() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }
    func pendingRequests() async -> [UNNotificationRequest] { await center.pendingNotificationRequests() }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removePending(identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
}

/// Reconciles only our Match reminders. Never requests permission outside onboarding.
@Observable
final class ReminderScheduler: NSObject, UNUserNotificationCenterDelegate, ReminderScheduling {
    var openedMatchId: String?
    #if DEBUG
    var deliveryProbeReady = false
    #endif
    private(set) var denied = false
    private(set) var errorMessage: String?
    private let center: UNUserNotificationCenter
    private let notifications: any ReminderNotificationCenter
    private var desired: [MatchReminder] = []
    private var revision = 0
    private var syncing = false

    init(center: UNUserNotificationCenter = .current(), notifications: (any ReminderNotificationCenter)? = nil) {
        self.center = center
        self.notifications = notifications ?? SystemReminderNotificationCenter(center: center)
        super.init()
    }

    func activate() { center.delegate = self }

    func bind(userId: String?) async {
        let status = await notifications.authorizationStatus()
        guard !Task.isCancelled else { return }
        denied = status == .denied
        let key = "reminderAccountId"
        if UserDefaults.standard.string(forKey: key) != userId {
            UserDefaults.standard.set(userId, forKey: key)
            await sync([])
        }
    }

    func sourceFailed() {
        errorMessage = "Couldn't refresh Match reminders. Return to the app to try again."
    }

    func sync(_ reminders: [MatchReminder]) async {
        desired = reminders
        revision += 1
        guard !syncing else { return }
        syncing = true
        defer { syncing = false }
        while true {
            let version = revision
            let target = desired
            let status = await notifications.authorizationStatus()
            denied = status == .denied
            let allowed = [.authorized, .provisional, .ephemeral].contains(status)
            let pending = await notifications.pendingRequests()
            if version != revision { continue }
            let ids = Set(allowed ? target.map(\.identifier) : [])
            notifications.removePending(identifiers: pending.map(\.identifier).filter {
                $0.hasPrefix("match-") && !ids.contains($0)
            })
            errorMessage = nil
            if allowed {
                for reminder in target {
                    if version != revision { break }
                    let content = UNMutableNotificationContent()
                    content.title = reminder.title
                    content.body = reminder.venue
                    content.sound = .default
                    content.userInfo = ["matchId": reminder.matchId]
                    let components = Self.triggerComponents(for: reminder.fireDate)
                    if let existing = pending.first(where: { $0.identifier == reminder.identifier }),
                       existing.content.title == reminder.title, existing.content.body == reminder.venue,
                       existing.content.userInfo["matchId"] as? String == reminder.matchId,
                       let trigger = existing.trigger as? UNCalendarNotificationTrigger,
                       trigger.dateComponents == components { continue }
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    do {
                        try await notifications.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
                    } catch {
                        errorMessage = "Couldn't update Match reminders. We'll try again when you return."
                    }
                }
            }
            if version == revision { break }
        }
    }

    static func triggerComponents(for date: Date) -> DateComponents {
        // Pin the instant to UTC/Gregorian so travel and non-Gregorian phone calendars cannot move it.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        return components
    }

    func openMatch(from userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["matchId"] as? String, !id.isEmpty else { return }
        openedMatchId = id
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let id = response.notification.request.content.userInfo["matchId"] as? String else {
            completionHandler()
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.openMatch(from: ["matchId": id])
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
