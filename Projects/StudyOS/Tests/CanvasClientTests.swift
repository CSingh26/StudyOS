import Canvas
import Core
import XCTest

final class CanvasClientTests: XCTestCase {
    func testFetchCoursesDecodes() async throws {
        let tokenStore = CanvasTokenStore()
        let profileId = UUID()
        try tokenStore.save(CanvasToken(accessToken: "token"), profileId: profileId)

        let coursesJSON = """
        [
          {"id": 1, "name": "Biology", "course_code": "BIO101"},
          {"id": 2, "name": "History", "course_code": "HIS201"}
        ]
        """
        let client = CanvasAPIClient(
            baseURL: URL(string: "https://example.com")!,
            profileId: profileId,
            tokenStore: tokenStore,
            httpClient: MockHTTPClient(responses: ["/api/v1/courses": Data(coursesJSON.utf8)])
        )

        let courses = try await client.fetchCourses()
        XCTAssertEqual(courses.count, 2)
        XCTAssertEqual(courses.first?.courseCode, "BIO101")
    }

    func testFetchAssignmentsDecodes() async throws {
        let tokenStore = CanvasTokenStore()
        let profileId = UUID()
        try tokenStore.save(CanvasToken(accessToken: "token"), profileId: profileId)

        let assignmentsJSON = """
        [
          {"id": 10, "name": "Essay", "due_at": "2024-03-01T17:00:00Z", "course_id": 1, "submission_types": ["online_upload"], "points_possible": 10}
        ]
        """
        let client = CanvasAPIClient(
            baseURL: URL(string: "https://example.com")!,
            profileId: profileId,
            tokenStore: tokenStore,
            httpClient: MockHTTPClient(responses: ["/api/v1/courses/1/assignments": Data(assignmentsJSON.utf8)])
        )

        let assignments = try await client.fetchAssignments(courseId: 1)
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.submissionTypes?.first, "online_upload")
    }
}

private final class MockHTTPClient: HTTPClient {
    let responses: [String: Data]

    init(responses: [String: Data]) {
        self.responses = responses
    }

    func send<T>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T where T: Decodable {
        guard let data = responses[endpoint.path] else {
            throw HTTPClientError.invalidResponse
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func send(_ endpoint: Endpoint) async throws {
        return
    }
}
