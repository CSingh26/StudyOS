import AuthenticationServices
import Canvas
import Core
import Foundation
import Storage
import SwiftUI

@MainActor
final class CanvasAuthViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isConnecting = false
    @Published var statusMessage: String?

    private let oauthService = CanvasOAuthService(httpClient: URLSessionHTTPClient())
    private let tokenStore = CanvasTokenStore()
    private var session: ASWebAuthenticationSession?
    private var pendingState: String?
    private var pendingVerifier: String?

    func startOAuth(profile: Profile) {
        guard let baseURLString = profile.canvasBaseURL,
              let baseURL = URL(string: baseURLString),
              let clientId = profile.canvasClientId,
              let redirectURI = profile.canvasRedirectURI else {
            statusMessage = "Canvas configuration incomplete."
            return
        }

        let scopes = (profile.canvasScopes ?? "url:GET|/api/v1/*").split(separator: " ").map(String.init)
        let config = CanvasOAuthConfig(
            baseURL: baseURL,
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: scopes
        )

        let pkce = PKCE.generate()
        let state = UUID().uuidString
        pendingState = state
        pendingVerifier = pkce.codeVerifier

        let authURL: URL
        do {
            authURL = try oauthService.authorizationURL(config: config, state: state, codeChallenge: pkce.codeChallenge)
        } catch {
            statusMessage = error.localizedDescription
            return
        }

        guard let callbackScheme = URL(string: redirectURI)?.scheme else {
            statusMessage = "Invalid redirect URI."
            return
        }

        isConnecting = true
        statusMessage = nil

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            guard let self else { return }
            Task { await self.handleCallback(url: callbackURL, error: error, config: config, profile: profile) }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        session.start()
        self.session = session
    }

    private func handleCallback(url: URL?, error: Error?, config: CanvasOAuthConfig, profile: Profile) async {
        defer { isConnecting = false }

        if let error {
            statusMessage = error.localizedDescription
            return
        }

        guard let url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
              returnedState == pendingState,
              let verifier = pendingVerifier else {
            statusMessage = "Authorization failed."
            return
        }

        do {
            let token = try await oauthService.exchangeCode(config: config, code: code, codeVerifier: verifier)
            try tokenStore.save(token, profileId: profile.id)
            statusMessage = "Canvas connected."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
