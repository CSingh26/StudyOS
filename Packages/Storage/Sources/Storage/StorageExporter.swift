import Foundation

public enum StorageExporter {
    public static func assignmentsToJSON(_ assignments: [Assignment]) throws -> Data {
        let export = assignments.map { AssignmentExport(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    public static func focusSessionsToJSON(_ sessions: [FocusSession]) throws -> Data {
        let export = sessions.map { FocusSessionExport(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    public static func assignmentsToCSV(_ assignments: [Assignment]) -> String {
        let header = "id,title,course,course_id,due_date,estimated_minutes,weight,status"
        let rows = assignments.map { assignment in
            [
                assignment.id.uuidString,
                sanitize(assignment.title),
                sanitize(assignment.course?.name ?? ""),
                assignment.course?.id.uuidString ?? "",
                iso8601(assignment.dueDate),
                String(assignment.estimatedMinutes),
                String(assignment.weight),
                assignment.status.rawValue
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    public static func focusSessionsToCSV(_ sessions: [FocusSession]) -> String {
        let header = "id,assignment_id,course_id,started_at,duration_minutes,notes,task_type"
        let rows = sessions.map { session in
            [
                session.id.uuidString,
                session.assignment?.id.uuidString ?? "",
                session.course?.id.uuidString ?? "",
                iso8601(session.startedAt),
                String(session.durationMinutes),
                sanitize(session.notes),
                session.taskType.rawValue
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private static func sanitize(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "\"", with: "\"\"")
        if cleaned.contains(",") || cleaned.contains("\n") {
            return "\"\(cleaned)\""
        }
        return cleaned
    }

    private static func iso8601(_ date: Date?) -> String {
        guard let date else { return "" }
        return ISO8601DateFormatter().string(from: date)
    }
}

private struct AssignmentExport: Codable {
    var id: UUID
    var title: String
    var dueDate: Date?
    var estimatedMinutes: Int
    var weight: Double
    var status: AssignmentStatus
    var courseId: UUID?
    var courseName: String?

    init(from assignment: Assignment) {
        self.id = assignment.id
        self.title = assignment.title
        self.dueDate = assignment.dueDate
        self.estimatedMinutes = assignment.estimatedMinutes
        self.weight = assignment.weight
        self.status = assignment.status
        self.courseId = assignment.course?.id
        self.courseName = assignment.course?.name
    }
}

private struct FocusSessionExport: Codable {
    var id: UUID
    var startedAt: Date
    var durationMinutes: Int
    var notes: String
    var taskType: TemplateKind
    var assignmentId: UUID?
    var courseId: UUID?

    init(from session: FocusSession) {
        self.id = session.id
        self.startedAt = session.startedAt
        self.durationMinutes = session.durationMinutes
        self.notes = session.notes
        self.taskType = session.taskType
        self.assignmentId = session.assignment?.id
        self.courseId = session.course?.id
    }
}
