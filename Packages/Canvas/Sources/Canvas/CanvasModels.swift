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

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct CanvasAssignmentDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var name: String
    public var dueAt: Date?
    public var courseId: Int

    public init(id: Int, name: String, dueAt: Date?, courseId: Int) {
        self.id = id
        self.name = name
        self.dueAt = dueAt
        self.courseId = courseId
    }
}

public struct CanvasQuizDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var title: String
    public var dueAt: Date?
    public var courseId: Int

    public init(id: Int, title: String, dueAt: Date?, courseId: Int) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.courseId = courseId
    }
}

public struct CanvasAnnouncementDTO: Sendable, Codable, Identifiable {
    public var id: Int
    public var title: String
    public var postedAt: Date?
    public var courseId: Int

    public init(id: Int, title: String, postedAt: Date?, courseId: Int) {
        self.id = id
        self.title = title
        self.postedAt = postedAt
        self.courseId = courseId
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
