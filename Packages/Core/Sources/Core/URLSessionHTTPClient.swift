import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let request = try endpoint.urlRequest()
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPClientError.decodingFailure
        }
    }

    public func send(_ endpoint: Endpoint) async throws {
        let request = try endpoint.urlRequest()
        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HTTPClientError.statusCode(httpResponse.statusCode)
        }
    }
}
