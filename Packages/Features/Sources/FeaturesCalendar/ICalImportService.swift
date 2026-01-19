import Core
import Storage
import SwiftData
import Foundation

@MainActor
final class ICalImportService {
    func importEvents(data: Data, context: ModelContext, source: CalendarEventSource) throws {
        let parsedEvents = try ICSParser.parse(data)
        for parsed in parsedEvents {
            if let uid = parsed.uid, hasEvent(with: uid, context: context) {
                continue
            }
            let event = CalendarEvent(
                title: parsed.summary,
                startDate: parsed.startDate,
                endDate: parsed.endDate,
                location: parsed.location,
                notes: parsed.description,
                source: source,
                externalId: parsed.uid
            )
            context.insert(event)
        }
        try context.save()
    }

    func refreshFeed(url: URL, context: ModelContext, profile: Profile) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        try importEvents(data: data, context: context, source: .ical)
        profile.lastIcalSyncAt = Date()
        try context.save()
    }

    private func hasEvent(with uid: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.externalId == uid })
        let existing = (try? context.fetch(descriptor)) ?? []
        return !existing.isEmpty
    }
}
