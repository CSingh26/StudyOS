public struct FeatureFlags: Sendable {
    public var enableLLMIntegrations: Bool
    public var enableCloudKitSync: Bool
    public var enableBackgroundSync: Bool

    public init(
        enableLLMIntegrations: Bool = false,
        enableCloudKitSync: Bool = false,
        enableBackgroundSync: Bool = true
    ) {
        self.enableLLMIntegrations = enableLLMIntegrations
        self.enableCloudKitSync = enableCloudKitSync
        self.enableBackgroundSync = enableBackgroundSync
    }
}
