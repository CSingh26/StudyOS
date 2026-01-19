import Foundation
import SwiftData

public enum AssignmentStatus: String, Codable, CaseIterable {
    case notStarted
    case inProgress
    case submitted
}

public enum CalendarEventSource: String, Codable, CaseIterable {
    case canvas
    case ical
    case manual
}

public enum FileReferenceType: String, Codable, CaseIterable {
    case pdf
    case image
    case link
    case other
}

public enum StudyBlockStatus: String, Codable, CaseIterable {
    case planned
    case completed
    case missed
}

public enum TemplateKind: String, Codable, CaseIterable {
    case reading
    case writing
    case coding
    case problemSet
    case project
    case exam
    case quiz
    case other
}

@Model
public final class Profile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var isDemo: Bool
    public var activeProfile: Bool
    public var canvasBaseURL: String?
    public var canvasClientId: String?
    public var canvasRedirectURI: String?
    public var icalFeedURL: String?

    @Relationship(deleteRule: .cascade, inverse: \Course.profile)
    public var courses: [Course]

    @Relationship(deleteRule: .cascade, inverse: \AvailabilityBlock.profile)
    public var availabilityBlocks: [AvailabilityBlock]

    @Relationship(deleteRule: .cascade, inverse: \GroupProject.profile)
    public var groupProjects: [GroupProject]

    @Relationship(deleteRule: .cascade, inverse: \Template.profile)
    public var templates: [Template]

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        isDemo: Bool = false,
        activeProfile: Bool = false,
        canvasBaseURL: String? = nil,
        canvasClientId: String? = nil,
        canvasRedirectURI: String? = nil,
        icalFeedURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.isDemo = isDemo
        self.activeProfile = activeProfile
        self.canvasBaseURL = canvasBaseURL
        self.canvasClientId = canvasClientId
        self.canvasRedirectURI = canvasRedirectURI
        self.icalFeedURL = icalFeedURL
        self.courses = []
        self.availabilityBlocks = []
        self.groupProjects = []
        self.templates = []
    }
}

@Model
public final class Course {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var code: String
    public var colorHex: String
    public var createdAt: Date
    public var profile: Profile?

    @Relationship(deleteRule: .cascade, inverse: \Assignment.course)
    public var assignments: [Assignment]

    @Relationship(deleteRule: .cascade, inverse: \Quiz.course)
    public var quizzes: [Quiz]

    @Relationship(deleteRule: .cascade, inverse: \Announcement.course)
    public var announcements: [Announcement]

    @Relationship(deleteRule: .cascade, inverse: \Grade.course)
    public var grades: [Grade]

    @Relationship(deleteRule: .cascade, inverse: \CalendarEvent.course)
    public var calendarEvents: [CalendarEvent]

    @Relationship(deleteRule: .cascade, inverse: \NoteItem.course)
    public var notes: [NoteItem]

    @Relationship(deleteRule: .cascade, inverse: \FileReference.course)
    public var files: [FileReference]

    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        colorHex: String,
        createdAt: Date = Date(),
        profile: Profile? = nil
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.profile = profile
        self.assignments = []
        self.quizzes = []
        self.announcements = []
        self.grades = []
        self.calendarEvents = []
        self.notes = []
        self.files = []
    }
}

@Model
public final class Assignment {
    @Attribute(.unique) public var id: UUID
    public var title: String
    @Attribute(.indexed) public var dueDate: Date?
    public var details: String
    public var estimatedMinutes: Int
    public var weight: Double
    public var status: AssignmentStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \Subtask.assignment)
    public var subtasks: [Subtask]

    @Relationship(deleteRule: .cascade, inverse: \FocusSession.assignment)
    public var focusSessions: [FocusSession]

    @Relationship(deleteRule: .cascade, inverse: \NoteItem.assignment)
    public var notes: [NoteItem]

    @Relationship(deleteRule: .cascade, inverse: \FileReference.assignment)
    public var files: [FileReference]

    public init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        details: String = "",
        estimatedMinutes: Int = 60,
        weight: Double = 0,
        status: AssignmentStatus = .notStarted,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        course: Course? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.details = details
        self.estimatedMinutes = estimatedMinutes
        self.weight = weight
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.course = course
        self.subtasks = []
        self.focusSessions = []
        self.notes = []
        self.files = []
    }
}

@Model
public final class Quiz {
    @Attribute(.unique) public var id: UUID
    public var title: String
    @Attribute(.indexed) public var dueDate: Date?
    public var totalPoints: Double
    public var course: Course?

    public init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        totalPoints: Double = 0,
        course: Course? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.totalPoints = totalPoints
        self.course = course
    }
}

@Model
public final class Announcement {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var message: String
    public var postedAt: Date
    public var course: Course?

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        postedAt: Date = Date(),
        course: Course? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.postedAt = postedAt
        self.course = course
    }
}

@Model
public final class Grade {
    @Attribute(.unique) public var id: UUID
    public var score: Double
    public var weight: Double
    public var recordedAt: Date
    public var course: Course?

    public init(
        id: UUID = UUID(),
        score: Double,
        weight: Double,
        recordedAt: Date = Date(),
        course: Course? = nil
    ) {
        self.id = id
        self.score = score
        self.weight = weight
        self.recordedAt = recordedAt
        self.course = course
    }
}

@Model
public final class CalendarEvent {
    @Attribute(.unique) public var id: UUID
    public var title: String
    @Attribute(.indexed) public var startDate: Date
    public var endDate: Date
    public var location: String
    public var notes: String
    public var source: CalendarEventSource
    public var externalId: String?
    public var course: Course?

    public init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        location: String = "",
        notes: String = "",
        source: CalendarEventSource = .manual,
        externalId: String? = nil,
        course: Course? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.source = source
        self.externalId = externalId
        self.course = course
    }
}

@Model
public final class StudyBlock {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var startDate: Date
    public var endDate: Date
    public var status: StudyBlockStatus
    public var assignment: Assignment?
    public var course: Course?

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        status: StudyBlockStatus = .planned,
        assignment: Assignment? = nil,
        course: Course? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.assignment = assignment
        self.course = course
    }
}

@Model
public final class FocusSession {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var startedAt: Date
    public var durationMinutes: Int
    public var notes: String
    public var assignment: Assignment?
    public var course: Course?
    public var taskType: TemplateKind

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        durationMinutes: Int,
        notes: String = "",
        assignment: Assignment? = nil,
        course: Course? = nil,
        taskType: TemplateKind = .other
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.assignment = assignment
        self.course = course
        self.taskType = taskType
    }
}

@Model
public final class NoteItem {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var ocrText: String
    public var createdAt: Date
    public var course: Course?
    public var assignment: Assignment?

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        ocrText: String = "",
        createdAt: Date = Date(),
        course: Course? = nil,
        assignment: Assignment? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.ocrText = ocrText
        self.createdAt = createdAt
        self.course = course
        self.assignment = assignment
    }
}

@Model
public final class FileReference {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var bookmarkData: Data
    public var type: FileReferenceType
    public var createdAt: Date
    public var course: Course?
    public var assignment: Assignment?

    public init(
        id: UUID = UUID(),
        name: String,
        bookmarkData: Data,
        type: FileReferenceType,
        createdAt: Date = Date(),
        course: Course? = nil,
        assignment: Assignment? = nil
    ) {
        self.id = id
        self.name = name
        self.bookmarkData = bookmarkData
        self.type = type
        self.createdAt = createdAt
        self.course = course
        self.assignment = assignment
    }
}

@Model
public final class Template {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var kind: TemplateKind
    public var defaultMinutes: Int
    public var profile: Profile?

    @Relationship(deleteRule: .cascade, inverse: \Subtask.template)
    public var subtasks: [Subtask]

    public init(
        id: UUID = UUID(),
        title: String,
        kind: TemplateKind,
        defaultMinutes: Int = 30,
        profile: Profile? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.defaultMinutes = defaultMinutes
        self.profile = profile
        self.subtasks = []
    }
}

@Model
public final class Subtask {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var estimatedMinutes: Int
    public var orderIndex: Int
    public var assignment: Assignment?
    public var template: Template?

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        estimatedMinutes: Int = 20,
        orderIndex: Int = 0,
        assignment: Assignment? = nil,
        template: Template? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.estimatedMinutes = estimatedMinutes
        self.orderIndex = orderIndex
        self.assignment = assignment
        self.template = template
    }
}

@Model
public final class AvailabilityBlock {
    @Attribute(.unique) public var id: UUID
    public var startDate: Date
    public var endDate: Date
    public var profile: Profile?

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        profile: Profile? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.profile = profile
    }
}

@Model
public final class GroupProject {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String
    public var createdAt: Date
    public var profile: Profile?

    @Relationship(deleteRule: .cascade, inverse: \Milestone.groupProject)
    public var milestones: [Milestone]

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        createdAt: Date = Date(),
        profile: Profile? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.profile = profile
        self.milestones = []
    }
}

@Model
public final class Milestone {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var dueDate: Date
    public var isCompleted: Bool
    public var groupProject: GroupProject?

    public init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date,
        isCompleted: Bool = false,
        groupProject: GroupProject? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.groupProject = groupProject
    }
}
