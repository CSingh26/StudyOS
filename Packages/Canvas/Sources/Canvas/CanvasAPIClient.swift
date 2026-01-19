import Core
import Foundation

public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let initialDelay: TimeInterval

    public init(maxAttempts: Int = 3, initialDelay: TimeInterval = 0.4) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
    }
}

public final class CanvasAPIClient: CanvasClient {
    private let httpClient: HTTPClient
    private let baseURL: URL
    private let tokenStore: CanvasTokenStore
    private let profileId: UUID
    private let retryPolicy: RetryPolicy

    public init(
        baseURL: URL,
        profileId: UUID,
        tokenStore: CanvasTokenStore = CanvasTokenStore(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        retryPolicy: RetryPolicy = RetryPolicy()
    ) {
        self.baseURL = baseURL
        self.profileId = profileId
        self.tokenStore = tokenStore
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
    }

    public func fetchCourses() async throws -> [CanvasCourseDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/courses", queryItems: [
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "enrollment_state", value: "active")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasCourseDTO].self)
    }

    public func fetchAssignments(courseId: Int) async throws -> [CanvasAssignmentDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/courses/\(courseId)/assignments", queryItems: [
            URLQueryItem(name: "per_page", value: "50")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasAssignmentDTO].self)
    }

    public func fetchQuizzes(courseId: Int) async throws -> [CanvasQuizDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/courses/\(courseId)/quizzes", queryItems: [
            URLQueryItem(name: "per_page", value: "50")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasQuizDTO].self)
    }

    public func fetchAnnouncements(courseId: Int) async throws -> [CanvasAnnouncementDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/announcements", queryItems: [
            URLQueryItem(name: "context_codes[]", value: "course_\(courseId)"),
            URLQueryItem(name: "per_page", value: "50")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasAnnouncementDTO].self)
    }

    public func fetchGrades(courseId: Int) async throws -> [CanvasGradeDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/courses/\(courseId)/enrollments", queryItems: [
            URLQueryItem(name: "type[]", value: "student"),
            URLQueryItem(name: "per_page", value: "50")
        ])
        let enrollments = try await sendWithRetry(endpoint, responseType: [CanvasEnrollmentDTO].self)
        return enrollments.compactMap { enrollment in
            guard let score = enrollment.grades?.currentScore else { return nil }
            return CanvasGradeDTO(id: enrollment.id, score: score, courseId: enrollment.courseId)
        }
    }

    public func fetchModules(courseId: Int) async throws -> [CanvasModuleDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/courses/\(courseId)/modules", queryItems: [
            URLQueryItem(name: "per_page", value: "50")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasModuleDTO].self)
    }

    public func fetchCalendarEvents() async throws -> [CanvasCalendarEventDTO] {
        let endpoint = try authorizedEndpoint(path: "/api/v1/calendar_events", queryItems: [
            URLQueryItem(name: "type", value: "event"),
            URLQueryItem(name: "per_page", value: "50")
        ])
        return try await sendWithRetry(endpoint, responseType: [CanvasCalendarEventDTO].self)
    }

    private func authorizedEndpoint(path: String, queryItems: [URLQueryItem]) throws -> Endpoint {
        guard let token = try tokenStore.load(profileId: profileId)?.accessToken else {
            throw CanvasError.unauthorized
        }
        return Endpoint(
            baseURL: baseURL,
            path: path,
            method: .get,
            queryItems: queryItems,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    private func sendWithRetry<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        var attempt = 0
        var delay = retryPolicy.initialDelay
        var lastError: Error?

        while attempt < retryPolicy.maxAttempts {
            do {
                return try await httpClient.send(endpoint, responseType: responseType)
            } catch {
                lastError = error
                guard shouldRetry(error: error) else { break }
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay *= 2
            }
        }
        throw lastError ?? CanvasError.invalidResponse
    }

    private func shouldRetry(error: Error) -> Bool {
        if let httpError = error as? HTTPClientError {
            switch httpError {
            case .statusCode(let code):
                return code == 429 || (500..<600).contains(code)
            default:
                return false
            }
        }
        return false
    }
}
