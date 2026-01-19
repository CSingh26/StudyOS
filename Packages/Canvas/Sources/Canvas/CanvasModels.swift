import Foundation

public struct CanvasOAuthConfig: Sendable, Codable {
    public var baseURL: URL
    public var clientId: String
    public var redirectURI: String
    public var scopes: [String]

    public init(baseURL: URL, clientId: String, redirectURI: String, scopes: [String]) {
        self.baseURL = baseURL
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}

public struct CanvasToken: Sendable, Codable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Date?

    public init(accessToken: String, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public struct CanvasCourseDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var name: String
    public var courseCode: String?

    public init(id: Int, name: String, courseCode: String? = nil) {
        self.id = id
        self.name = name
        self.courseCode = courseCode
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
    }
}

public struct CanvasAssignmentDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var name: String
    public var dueAt: Date?
    public var courseId: Int
    public var description: String?
    public var pointsPossible: Double?
    public var submissionTypes: [String]?
    public var htmlURL: String?

    public init(
        id: Int,
        name: String,
        dueAt: Date?,
        courseId: Int,
        description: String? = nil,
        pointsPossible: Double? = nil,
        submissionTypes: [String]? = nil,
        htmlURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dueAt = dueAt
        self.courseId = courseId
        self.description = description
        self.pointsPossible = pointsPossible
        self.submissionTypes = submissionTypes
        self.htmlURL = htmlURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dueAt = "due_at"
        case courseId = "course_id"
        case description
        case pointsPossible = "points_possible"
        case submissionTypes = "submission_types"
        case htmlURL = "html_url"
    }
}

public struct CanvasQuizDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var title: String
    public var dueAt: Date?
    public var courseId: Int
    public var pointsPossible: Double?
    public var htmlURL: String?

    public init(id: Int, title: String, dueAt: Date?, courseId: Int, pointsPossible: Double? = nil, htmlURL: String? = nil) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.courseId = courseId
        self.pointsPossible = pointsPossible
        self.htmlURL = htmlURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case dueAt = "due_at"
        case courseId = "course_id"
        case pointsPossible = "points_possible"
        case htmlURL = "html_url"
    }
}

public struct CanvasAnnouncementDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var title: String
    public var message: String?
    public var postedAt: Date?
    public var contextCode: String?
    public var htmlURL: String?

    public init(id: Int, title: String, message: String? = nil, postedAt: Date? = nil, contextCode: String? = nil, htmlURL: String? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.postedAt = postedAt
        self.contextCode = contextCode
        self.htmlURL = htmlURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case postedAt = "posted_at"
        case contextCode = "context_code"
        case htmlURL = "html_url"
    }
}

public struct CanvasGradeDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var score: Double
    public var courseId: Int

    public init(id: Int, score: Double, courseId: Int) {
        self.id = id
        self.score = score
        self.courseId = courseId
    }
}

public struct CanvasCalendarEventDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var title: String
    public var startAt: Date?
    public var endAt: Date?
    public var contextCode: String?
    public var locationName: String?
    public var description: String?
    public var htmlURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startAt = "start_at"
        case endAt = "end_at"
        case contextCode = "context_code"
        case locationName = "location_name"
        case description
        case htmlURL = "html_url"
    }
}

public struct CanvasModuleDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var name: String
    public var position: Int?
    public var published: Bool?
}

public struct CanvasEnrollmentDTO: Sendable, Codable, Identifiable {
    public struct Grades: Sendable, Codable {
        public var currentScore: Double?

        enum CodingKeys: String, CodingKey {
            case currentScore = "current_score"
        }
    }

    public var id: Int
    public var courseId: Int
    public var grades: Grades?

    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case grades
    }
}
