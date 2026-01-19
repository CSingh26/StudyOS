import EventKit
import Foundation

public protocol EventKitClient {
    func fetchEvents(start: Date, end: Date) async throws -> [EKEvent]
}

public final class DefaultEventKitClient: EventKitClient {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func fetchEvents(start: Date, end: Date) async throws -> [EKEvent] {
        try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(to: .event) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard granted else {
                    continuation.resume(returning: [])
                    return
                }
                let predicate = self.store.predicateForEvents(withStart: start, end: end, calendars: nil)
                let events = self.store.events(matching: predicate)
                continuation.resume(returning: events)
            }
        }
    }
}
