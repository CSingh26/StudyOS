import Foundation

public protocol CanvasClient: Sendable {
    func fetchCourses() async throws -> [CanvasCourseDTO]
    func fetchAssignments(courseId: Int) async throws -> [CanvasAssignmentDTO]
    func fetchQuizzes(courseId: Int) async throws -> [CanvasQuizDTO]
    func fetchAnnouncements(courseId: Int) async throws -> [CanvasAnnouncementDTO]
    func fetchGrades(courseId: Int) async throws -> [CanvasGradeDTO]
    func fetchModules(courseId: Int) async throws -> [CanvasModuleDTO]
    func fetchCalendarEvents() async throws -> [CanvasCalendarEventDTO]
}

public enum CanvasError: LocalizedError {
    case missingConfiguration
    case unauthorized
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Canvas configuration is missing."
        case .unauthorized:
            return "Canvas authorization failed."
        case .invalidResponse:
            return "Canvas response invalid."
        }
    }
}
