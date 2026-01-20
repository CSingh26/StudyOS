import EventKit
import Storage

enum StudyBlockCalendarExporter {
    static func export(blocks: [Storage.StudyBlock]) async {
        let store = EKEventStore()
        let granted = await requestAccess(store: store)
        guard granted else { return }

        let calendar = fetchOrCreateCalendar(store: store)
        removeExistingEvents(in: blocks, store: store, calendar: calendar)
        for block in blocks {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = block.assignment?.title ?? "Study Block"
            event.startDate = block.startDate
            event.endDate = block.endDate
            event.notes = "StudyOS planned block"
            try? store.save(event, span: .thisEvent)
        }
    }

    private static func requestAccess(store: EKEventStore) async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func fetchOrCreateCalendar(store: EKEventStore) -> EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == "StudyOS" }) {
            return existing
        }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "StudyOS"
        calendar.source = store.defaultCalendarForNewEvents?.source
        try? store.saveCalendar(calendar, commit: true)
        return calendar
    }

    private static func removeExistingEvents(in blocks: [Storage.StudyBlock], store: EKEventStore, calendar: EKCalendar) {
        guard let earliest = blocks.map(\.startDate).min(),
              let latest = blocks.map(\.endDate).max() else { return }
        let predicate = store.predicateForEvents(withStart: earliest, end: latest, calendars: [calendar])
        let existing = store.events(matching: predicate)
        for event in existing {
            try? store.remove(event, span: .thisEvent)
        }
    }
}
