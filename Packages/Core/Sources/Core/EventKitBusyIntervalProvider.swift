import EventKit
import Foundation

public enum EventKitBusyIntervalProvider {
    public static func busyIntervals(start: Date, end: Date, client: EventKitClient) async throws -> [DateInterval] {
        let events = try await client.fetchEvents(start: start, end: end)
        return events.map { DateInterval(start: $0.startDate, end: $0.endDate) }
    }
}
