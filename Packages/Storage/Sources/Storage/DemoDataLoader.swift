import Foundation
import SwiftData

public enum DemoDataLoader {
    public static func loadSeedData() throws -> DemoDataSeed {
        guard let url = Bundle.module.url(forResource: "DemoData", withExtension: "json") else {
            throw StorageError.demoDataMissing
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DemoDataSeed.self, from: data)
    }

    @MainActor
    @discardableResult
    public static func seed(into context: ModelContext) throws -> [Profile] {
        let seed = try loadSeedData()
        var profiles: [Profile] = []

        for profileSeed in seed.profiles {
            let profile = Profile(
                id: profileSeed.id,
                name: profileSeed.name,
                createdAt: profileSeed.createdAt,
                isDemo: profileSeed.isDemo,
                activeProfile: profileSeed.activeProfile
            )
            context.insert(profile)

            for courseSeed in profileSeed.courses {
                let course = Course(
                    id: courseSeed.id,
                    name: courseSeed.name,
                    code: courseSeed.code,
                    colorHex: courseSeed.colorHex,
                    createdAt: courseSeed.createdAt,
                    profile: profile
                )
                context.insert(course)

                for assignmentSeed in courseSeed.assignments {
                    let assignment = Assignment(
                        id: assignmentSeed.id,
                        title: assignmentSeed.title,
                        dueDate: assignmentSeed.dueDate,
                        details: assignmentSeed.details,
                        estimatedMinutes: assignmentSeed.estimatedMinutes,
                        weight: assignmentSeed.weight,
                        status: assignmentSeed.status,
                        createdAt: assignmentSeed.createdAt,
                        updatedAt: assignmentSeed.updatedAt,
                        course: course
                    )
                    context.insert(assignment)

                    for subtaskSeed in assignmentSeed.subtasks {
                        let subtask = Subtask(
                            id: subtaskSeed.id,
                            title: subtaskSeed.title,
                            isCompleted: subtaskSeed.isCompleted,
                            estimatedMinutes: subtaskSeed.estimatedMinutes,
                            orderIndex: subtaskSeed.orderIndex,
                            assignment: assignment
                        )
                        context.insert(subtask)
                    }
                }

                for eventSeed in courseSeed.calendarEvents {
                    let event = CalendarEvent(
                        id: eventSeed.id,
                        title: eventSeed.title,
                        startDate: eventSeed.startDate,
                        endDate: eventSeed.endDate,
                        location: eventSeed.location,
                        notes: eventSeed.notes,
                        source: eventSeed.source,
                        externalId: eventSeed.externalId,
                        course: course
                    )
                    context.insert(event)
                }

                for noteSeed in courseSeed.notes {
                    let note = NoteItem(
                        id: noteSeed.id,
                        title: noteSeed.title,
                        content: noteSeed.content,
                        ocrText: noteSeed.ocrText,
                        createdAt: noteSeed.createdAt,
                        course: course
                    )
                    context.insert(note)
                }
            }

            profiles.append(profile)
        }

        try context.save()
        return profiles
    }
}

public struct DemoDataSeed: Codable {
    public var profiles: [ProfileSeed]
}

public struct ProfileSeed: Codable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var isDemo: Bool
    public var activeProfile: Bool
    public var courses: [CourseSeed]
}

public struct CourseSeed: Codable {
    public var id: UUID
    public var name: String
    public var code: String
    public var colorHex: String
    public var createdAt: Date
    public var assignments: [AssignmentSeed]
    public var calendarEvents: [CalendarEventSeed]
    public var notes: [NoteSeed]
}

public struct AssignmentSeed: Codable {
    public var id: UUID
    public var title: String
    public var dueDate: Date?
    public var details: String
    public var estimatedMinutes: Int
    public var weight: Double
    public var status: AssignmentStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var subtasks: [SubtaskSeed]
}

public struct SubtaskSeed: Codable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var estimatedMinutes: Int
    public var orderIndex: Int
}

public struct CalendarEventSeed: Codable {
    public var id: UUID
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var location: String
    public var notes: String
    public var source: CalendarEventSource
    public var externalId: String?
}

public struct NoteSeed: Codable {
    public var id: UUID
    public var title: String
    public var content: String
    public var ocrText: String
    public var createdAt: Date
}
