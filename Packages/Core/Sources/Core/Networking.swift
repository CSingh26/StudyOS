import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public struct Endpoint: Sendable {
    public var baseURL: URL
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        baseURL: URL,
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }

    public func urlRequest() throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw CoreError.invalidURL
        }
        components.path = components.path + path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw CoreError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

public protocol HTTPClient: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T
    func send(_ endpoint: Endpoint) async throws
}

public enum HTTPClientError: LocalizedError {
    case invalidResponse
    case statusCode(Int)
    case decodingFailure

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response."
        case .statusCode(let code):
            return "Unexpected status code: \(code)."
        case .decodingFailure:
            return "Unable to decode response."
        }
    }
}
