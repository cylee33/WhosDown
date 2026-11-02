import CoreLocation
import Foundation
import UserNotifications

/// The two system prompts in onboarding (1.4, H05). Each prompt shows at most once; iOS remembers the answer.
protocol PermissionsService {
    /// Asks for location while using the app; returns whether it was allowed.
    func requestLocation() async -> Bool
    /// Asks for notifications (Match reminders, 1.24); returns whether they were allowed.
    func requestNotifications() async -> Bool
}

final class SystemPermissionsService: NSObject, PermissionsService, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocation() async -> Bool {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return true
        case .denied, .restricted: return false
        default: break
        }
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestNotifications() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
            locationContinuation = nil
        }
    }
}
