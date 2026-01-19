import Core
import Planner
import Storage
import SwiftData
import UserNotifications

public struct NotificationPreferences: Sendable {
    public var assignmentReminders: Bool
    public var studyBlockReminders: Bool
    public var classReminders: Bool

    public init(assignmentReminders: Bool, studyBlockReminders: Bool, classReminders: Bool) {
        self.assignmentReminders = assignmentReminders
        self.studyBlockReminders = studyBlockReminders
        self.classReminders = classReminders
    }
}

public enum NotificationScheduler {
    public static func scheduleAll(
        context: ModelContext,
        preferences: NotificationPreferences,
        weights: PriorityWeights
    ) async {
        let center = UNUserNotificationCenter.current()
        let granted = await requestAuthorization(center: center)
        guard granted else { return }

        let assignments = (try? context.fetch(FetchDescriptor<Assignment>())) ?? []
        let studyBlocks = (try? context.fetch(FetchDescriptor<StudyBlock>())) ?? []
        let events = (try? context.fetch(FetchDescriptor<CalendarEvent>())) ?? []

        var identifiers: [String] = []

        if preferences.assignmentReminders {
            identifiers.append(contentsOf: scheduleAssignments(assignments, weights: weights, center: center))
        }
        if preferences.studyBlockReminders {
            identifiers.append(contentsOf: scheduleStudyBlocks(studyBlocks, center: center))
        }
        if preferences.classReminders {
            identifiers.append(contentsOf: scheduleClassEvents(events, center: center))
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        for identifier in identifiers {
            if let request = pendingRequests[identifier] {
                center.add(request)
            }
        }
        pendingRequests.removeAll()
    }

    private static var pendingRequests: [String: UNNotificationRequest] = [:]

    private static func requestAuthorization(center: UNUserNotificationCenter) async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    private static func scheduleAssignments(
        _ assignments: [Assignment],
        weights: PriorityWeights,
        center: UNUserNotificationCenter
    ) -> [String] {
        var identifiers: [String] = []
        let now = Date()

        for assignment in assignments {
            guard let dueDate = assignment.dueDate, dueDate > now else { continue }
            let task = StudyTask(
                title: assignment.title,
                dueDate: dueDate,
                estimatedMinutes: assignment.estimatedMinutes,
                type: .other,
                weight: assignment.weight,
                status: taskStatus(from: assignment.status)
            )
            let score = PriorityScorer.score(task: task, weights: weights, now: now)
            let isHighPriority = score >= 0.75 || assignment.estimatedMinutes >= 120
            let earlyHours = isHighPriority ? 24 : 6
            let earlyDate = dueDate.addingTimeInterval(TimeInterval(-earlyHours * 3600))
            let finalDate = dueDate.addingTimeInterval(TimeInterval(-2 * 3600))

            if earlyDate > now {
                let identifier = "assignment-early-\(assignment.id.uuidString)"
                identifiers.append(identifier)
                pendingRequests[identifier] = makeRequest(
                    identifier: identifier,
                    title: "Upcoming deadline",
                    body: "\(assignment.title) is due soon.",
                    date: earlyDate
                )
            }

            if finalDate > now {
                let identifier = "assignment-final-\(assignment.id.uuidString)"
                identifiers.append(identifier)
                pendingRequests[identifier] = makeRequest(
                    identifier: identifier,
                    title: "Deadline reminder",
                    body: "\(assignment.title) is due today.",
                    date: finalDate
                )
            }
        }

        return identifiers
    }

    private static func taskStatus(from status: AssignmentStatus) -> StudyTaskStatus {
        switch status {
        case .notStarted:
            return .notStarted
        case .inProgress:
            return .inProgress
        case .submitted:
            return .completed
        }
    }

    private static func scheduleStudyBlocks(_ blocks: [StudyBlock], center: UNUserNotificationCenter) -> [String] {
        var identifiers: [String] = []
        let now = Date()

        for block in blocks where block.startDate > now {
            let fireDate = block.startDate.addingTimeInterval(-10 * 60)
            guard fireDate > now else { continue }
            let identifier = "studyblock-\(block.id.uuidString)"
            identifiers.append(identifier)
            let title = block.assignment?.title ?? "Study block"
            pendingRequests[identifier] = makeRequest(
                identifier: identifier,
                title: "Study block starting",
                body: "\(title) starts soon.",
                date: fireDate
            )
        }

        return identifiers
    }

    private static func scheduleClassEvents(_ events: [CalendarEvent], center: UNUserNotificationCenter) -> [String] {
        var identifiers: [String] = []
        let now = Date()

        for event in events where event.startDate > now {
            let fireDate = event.startDate.addingTimeInterval(-15 * 60)
            guard fireDate > now else { continue }
            let identifier = "class-\(event.id.uuidString)"
            identifiers.append(identifier)
            pendingRequests[identifier] = makeRequest(
                identifier: identifier,
                title: "Class reminder",
                body: "\(event.title) starts in 15 minutes.",
                date: fireDate
            )
        }

        return identifiers
    }

    private static func makeRequest(identifier: String, title: String, body: String, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
