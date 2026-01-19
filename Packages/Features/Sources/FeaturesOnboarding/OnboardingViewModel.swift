import EventKit
import Foundation
import UserNotifications
import CoreLocation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case permissions
        case mode
        case profile
        case finish
    }

    enum Mode: String, CaseIterable {
        case canvas = "Canvas"
        case ical = "iCal"
        case demo = "Demo"
    }

    enum PermissionStatus: String {
        case unknown
        case granted
        case denied
    }

    @Published var step: Step = .welcome
    @Published var notificationsStatus: PermissionStatus = .unknown
    @Published var calendarStatus: PermissionStatus = .unknown
    @Published var locationStatus: PermissionStatus = .unknown
    @Published var wantsLocation: Bool = false
    @Published var selectedMode: Mode = .demo
    @Published var profileName: String = ""
    @Published var canvasBaseURL: String = ""
    @Published var icalFeedURL: String = ""
    @Published var errorMessage: String?

    private let eventStore = EKEventStore()
    private let locationRequester = LocationPermissionRequester()

    init() {
        locationRequester.onStatusChange = { [weak self] status in
            guard let self else { return }
            self.locationStatus = status
        }
    }

    func requestNotifications() async {
        do {
            let granted = try await NotificationPermissionRequester.request()
            notificationsStatus = granted ? .granted : .denied
        } catch {
            notificationsStatus = .denied
            errorMessage = error.localizedDescription
        }
    }

    func requestCalendar() async {
        do {
            let granted = try await CalendarPermissionRequester.request(store: eventStore)
            calendarStatus = granted ? .granted : .denied
        } catch {
            calendarStatus = .denied
            errorMessage = error.localizedDescription
        }
    }

    func requestLocationIfNeeded() {
        guard wantsLocation else { return }
        locationRequester.requestWhenInUse()
    }
}

private enum NotificationPermissionRequester {
    static func request() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

private enum CalendarPermissionRequester {
    static func request(store: EKEventStore) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(to: .event) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

private final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onStatusChange: ((OnboardingViewModel.PermissionStatus) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
        notifyStatus(manager.authorizationStatus)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        notifyStatus(manager.authorizationStatus)
    }

    private func notifyStatus(_ status: CLAuthorizationStatus) {
        let mapped: OnboardingViewModel.PermissionStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapped = .granted
        case .denied, .restricted:
            mapped = .denied
        case .notDetermined:
            mapped = .unknown
        @unknown default:
            mapped = .unknown
        }
        onStatusChange?(mapped)
    }
}
