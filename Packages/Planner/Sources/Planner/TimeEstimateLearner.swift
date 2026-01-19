import Foundation

public struct FocusSessionRecord: Sendable, Hashable {
    public var courseId: UUID?
    public var taskType: TaskType
    public var durationMinutes: Int

    public init(courseId: UUID?, taskType: TaskType, durationMinutes: Int) {
        self.courseId = courseId
        self.taskType = taskType
        self.durationMinutes = durationMinutes
    }
}

public struct EstimateKey: Hashable, Sendable {
    public var courseId: UUID?
    public var taskType: TaskType

    public init(courseId: UUID?, taskType: TaskType) {
        self.courseId = courseId
        self.taskType = taskType
    }
}

public enum TimeEstimateLearner {
    public static func updateEstimates(
        current: [EstimateKey: Double],
        sessions: [FocusSessionRecord],
        alpha: Double = 0.3
    ) -> [EstimateKey: Double] {
        var updated = current
        for session in sessions {
            let key = EstimateKey(courseId: session.courseId, taskType: session.taskType)
            let existing = updated[key] ?? Double(session.durationMinutes)
            let newValue = (alpha * Double(session.durationMinutes)) + ((1 - alpha) * existing)
            updated[key] = newValue
        }
        return updated
    }
}
