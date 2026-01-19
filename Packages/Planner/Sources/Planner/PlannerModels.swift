import Foundation

public enum TaskType: String, Sendable, Codable {
    case reading
    case writing
    case coding
    case problemSet
    case project
    case exam
    case quiz
    case other
}

public struct StudyTask: Identifiable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var dueDate: Date?
    public var estimatedMinutes: Int
    public var type: TaskType
    public var courseId: UUID?

    public init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        estimatedMinutes: Int,
        type: TaskType,
        courseId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.type = type
        self.courseId = courseId
    }
}

public struct StudyBlock: Identifiable, Sendable, Codable {
    public let id: UUID
    public var taskId: UUID
    public var start: Date
    public var end: Date

    public init(id: UUID = UUID(), taskId: UUID, start: Date, end: Date) {
        self.id = id
        self.taskId = taskId
        self.start = start
        self.end = end
    }
}

public struct TimeWindow: Sendable, Codable, Equatable {
    public var startHour: Int
    public var endHour: Int

    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }
}

public struct PlannerConstraints: Sendable, Codable {
    public var maxHoursPerDay: Int
    public var preferredWindow: TimeWindow
    public var noStudyWindows: [TimeWindow]
    public var allowWeekends: Bool

    public init(
        maxHoursPerDay: Int = 4,
        preferredWindow: TimeWindow = TimeWindow(startHour: 9, endHour: 20),
        noStudyWindows: [TimeWindow] = [],
        allowWeekends: Bool = true
    ) {
        self.maxHoursPerDay = maxHoursPerDay
        self.preferredWindow = preferredWindow
        self.noStudyWindows = noStudyWindows
        self.allowWeekends = allowWeekends
    }
}

public struct PriorityWeights: Sendable, Codable {
    public var dueSoonFactor: Double
    public var effortFactor: Double
    public var weightFactor: Double
    public var statusFactor: Double
    public var courseImportance: Double

    public init(
        dueSoonFactor: Double = 0.35,
        effortFactor: Double = 0.2,
        weightFactor: Double = 0.25,
        statusFactor: Double = 0.1,
        courseImportance: Double = 0.1
    ) {
        self.dueSoonFactor = dueSoonFactor
        self.effortFactor = effortFactor
        self.weightFactor = weightFactor
        self.statusFactor = statusFactor
        self.courseImportance = courseImportance
    }
}
