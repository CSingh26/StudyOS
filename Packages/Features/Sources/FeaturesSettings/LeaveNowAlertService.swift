import CoreLocation
import MapKit
import Storage
import UserNotifications

@MainActor
public final class LeaveNowAlertService: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func requestAuthorizationIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    public func scheduleLeaveNowAlerts(events: [CalendarEvent]) async {
        requestAuthorizationIfNeeded()
        guard let location = try? await currentLocation() else {
            scheduleFallbackAlerts(events: events)
            return
        }

        let center = UNUserNotificationCenter.current()
        let now = Date()

        for event in events where event.startDate > now {
            guard let locationName = event.location.nonEmpty else { continue }
            do {
                let destination = try await findPlacemark(for: locationName)
                let travelTime = try await travelTime(from: location, to: destination)
                let fireDate = event.startDate.addingTimeInterval(-(travelTime + (10 * 60)))
                guard fireDate > now else { continue }

                let identifier = "leave-now-\(event.id.uuidString)"
                let content = UNMutableNotificationContent()
                content.title = "Leave now"
                content.body = "Time to leave for \(event.title)."
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await center.add(request)
            } catch {
                continue
            }
        }
    }

    private func scheduleFallbackAlerts(events: [CalendarEvent]) {
        let center = UNUserNotificationCenter.current()
        let now = Date()

        for event in events where event.startDate > now {
            let fireDate = event.startDate.addingTimeInterval(-20 * 60)
            guard fireDate > now else { continue }
            let identifier = "leave-now-fallback-\(event.id.uuidString)"
            let content = UNMutableNotificationContent()
            content.title = "Class soon"
            content.body = "\(event.title) starts soon."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: nil)
        }
    }

    private func currentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    private func findPlacemark(for query: String) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw NSError(domain: "LeaveNow", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location not found"]) 
        }
        return item
    }

    private func travelTime(from location: CLLocation, to destination: MKMapItem) async throws -> TimeInterval {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        return response.routes.first?.expectedTravelTime ?? 0
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
