import Foundation

public enum CoreError: LocalizedError {
    case invalidURL
    case missingData
    case decodingFailure
    case unauthorized
    case unsupported

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .missingData:
            return "Required data is missing."
        case .decodingFailure:
            return "Unable to decode response."
        case .unauthorized:
            return "Unauthorized."
        case .unsupported:
            return "This action is not supported."
        }
    }
}
