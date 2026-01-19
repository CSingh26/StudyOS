import Foundation

public struct FeatureContext: Sendable {
    public var profileId: UUID

    public init(profileId: UUID) {
        self.profileId = profileId
    }
}
