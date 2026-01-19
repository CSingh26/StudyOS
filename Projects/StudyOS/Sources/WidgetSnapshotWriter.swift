import Core
import Storage
import SwiftData
import WidgetKit

enum WidgetSnapshotWriter {
    static func update(context: ModelContext) {
        let assignments = (try? context.fetch(FetchDescriptor<Assignment>())) ?? []
        let events = (try? context.fetch(FetchDescriptor<CalendarEvent>())) ?? []

        let today = Date()
        let todayTasks = assignments
            .filter { $0.status != .submitted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(3)
            .map { assignment in
                WidgetTask(
                    id: assignment.id.uuidString,
                    title: assignment.title,
                    dueDate: assignment.dueDate,
                    courseName: assignment.course?.name
                )
            }

        let upcoming = assignments
            .filter { ($0.dueDate ?? .distantFuture) > today }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(3)
            .map { assignment in
                WidgetTask(
                    id: assignment.id.uuidString,
                    title: assignment.title,
                    dueDate: assignment.dueDate,
                    courseName: assignment.course?.name
                )
            }

        let nextEvent = events
            .filter { $0.startDate > today }
            .sorted { $0.startDate < $1.startDate }
            .first
            .map { event in
                WidgetEvent(title: event.title, startDate: event.startDate, location: event.location)
            }

        let snapshot = WidgetSnapshot(todayTasks: Array(todayTasks), upcomingDeadlines: Array(upcoming), nextClass: nextEvent)
        try? SharedSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
