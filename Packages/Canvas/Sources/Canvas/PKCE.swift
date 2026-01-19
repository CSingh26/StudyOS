import Foundation
import CryptoKit

public struct PKCEPair: Sendable {
    public let codeVerifier: String
    public let codeChallenge: String

    public init(codeVerifier: String, codeChallenge: String) {
        self.codeVerifier = codeVerifier
        self.codeChallenge = codeChallenge
    }
}

public enum PKCE {
    public static func generate() -> PKCEPair {
        let verifier = randomString(length: 64)
        let challenge = sha256Base64URL(verifier)
        return PKCEPair(codeVerifier: verifier, codeChallenge: challenge)
    }

    private static func randomString(length: Int) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let value = charset.randomElement() {
                result.append(value)
            }
        }
        return result
    }

    private static func sha256Base64URL(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        let base64 = Data(digest).base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
