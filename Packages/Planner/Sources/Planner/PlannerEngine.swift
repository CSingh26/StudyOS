import Foundation

public protocol PlannerEngine: Sendable {
    func plan(tasks: [StudyTask], constraints: PlannerConstraints) async throws -> [StudyBlock]
}

public enum PlannerError: LocalizedError {
    case invalidConstraints
    case schedulingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidConstraints:
            return "Invalid planning constraints."
        case .schedulingFailed:
            return "Unable to schedule study blocks."
        }
    }
}
