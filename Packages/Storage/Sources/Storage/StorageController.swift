import Foundation
import SwiftData

public struct StorageConfiguration: Sendable {
    public var appGroupId: String
    public var cloudKitContainerId: String?
    public var useCloudKit: Bool

    public init(appGroupId: String, cloudKitContainerId: String?, useCloudKit: Bool) {
        self.appGroupId = appGroupId
        self.cloudKitContainerId = cloudKitContainerId
        self.useCloudKit = useCloudKit
    }
}

public enum StorageError: LocalizedError {
    case containerUnavailable

    public var errorDescription: String? {
        switch self {
        case .containerUnavailable:
            return "Storage container unavailable."
        }
    }
}

public enum StorageController {
    public static func makeContainer(
        models: [any PersistentModel.Type],
        configuration: StorageConfiguration
    ) throws -> ModelContainer {
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: configuration.appGroupId)
        let configuration = ModelConfiguration(
            url: groupURL?.appendingPathComponent("StudyOS.sqlite"),
            cloudKitDatabase: configuration.useCloudKit ? .automatic : .none
        )
        return try ModelContainer(for: models, configurations: configuration)
    }
}

public protocol Repository {
    associatedtype Entity
    func fetchAll() async throws -> [Entity]
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
}
