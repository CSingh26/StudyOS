public struct AppConfig: Sendable {
    public var appGroupId: String
    public var cloudKitContainerId: String?

    public init(appGroupId: String, cloudKitContainerId: String?) {
        self.appGroupId = appGroupId
        self.cloudKitContainerId = cloudKitContainerId
    }
}
