import Core
import Foundation

public struct CanvasTokenResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int?
    public let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

public final class CanvasOAuthService {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func authorizationURL(config: CanvasOAuthConfig, state: String, codeChallenge: String) throws -> URL {
        let endpoint = Endpoint(
            baseURL: config.baseURL,
            path: "/login/oauth2/auth",
            method: .get,
            queryItems: [
                URLQueryItem(name: "client_id", value: config.clientId),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "redirect_uri", value: config.redirectURI),
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ]
        )
        return try endpoint.urlRequest().url ?? config.baseURL
    }

    public func exchangeCode(
        config: CanvasOAuthConfig,
        code: String,
        codeVerifier: String
    ) async throws -> CanvasToken {
        let body = formEncoded([
            "grant_type": "authorization_code",
            "client_id": config.clientId,
            "redirect_uri": config.redirectURI,
            "code": code,
            "code_verifier": codeVerifier
        ])

        let endpoint = Endpoint(
            baseURL: config.baseURL,
            path: "/login/oauth2/token",
            method: .post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )

        let response = try await httpClient.send(endpoint, responseType: CanvasTokenResponse.self)
        let expiresAt = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        return CanvasToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt
        )
    }

    public func refreshToken(
        config: CanvasOAuthConfig,
        refreshToken: String
    ) async throws -> CanvasToken {
        let body = formEncoded([
            "grant_type": "refresh_token",
            "client_id": config.clientId,
            "refresh_token": refreshToken
        ])

        let endpoint = Endpoint(
            baseURL: config.baseURL,
            path: "/login/oauth2/token",
            method: .post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )

        let response = try await httpClient.send(endpoint, responseType: CanvasTokenResponse.self)
        let expiresAt = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        return CanvasToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt
        )
    }

    private func formEncoded(_ params: [String: String]) -> Data? {
        let encoded = params.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }
        .joined(separator: "&")
        return encoded.data(using: .utf8)
    }
}

public final class CanvasTokenStore {
    private let service = "com.studyos.canvas.token"

    public init() {}

    public func save(_ token: CanvasToken, profileId: UUID) throws {
        let data = try JSONEncoder().encode(token)
        try KeychainClient.save(data, service: service, account: profileId.uuidString)
    }

    public func load(profileId: UUID) throws -> CanvasToken? {
        guard let data = try KeychainClient.load(service: service, account: profileId.uuidString) else {
            return nil
        }
        return try JSONDecoder().decode(CanvasToken.self, from: data)
    }

    public func delete(profileId: UUID) throws {
        try KeychainClient.delete(service: service, account: profileId.uuidString)
    }
}
