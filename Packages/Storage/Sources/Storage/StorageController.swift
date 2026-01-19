import Core
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
    case demoDataMissing

    public var errorDescription: String? {
        switch self {
        case .containerUnavailable:
            return "Storage container unavailable."
        case .demoDataMissing:
            return "Demo data missing."
        }
    }
}

public enum StorageController {
    public static func makeContainer(
        models: [any PersistentModel.Type],
        configuration: StorageConfiguration
    ) throws -> ModelContainer {
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: configuration.appGroupId)
        let modelConfiguration = ModelConfiguration(
            url: groupURL?.appendingPathComponent("StudyOS.sqlite"),
            cloudKitDatabase: configuration.useCloudKit ? .private : .none
        )
        return try ModelContainer(for: models, configurations: modelConfiguration)
    }

    public static func deleteStore(appGroupId: String) {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else { return }
        let base = groupURL.appendingPathComponent("StudyOS.sqlite")
        let urls = [base, base.appendingPathExtension("shm"), base.appendingPathExtension("wal")]
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

@MainActor
public final class SwiftDataRepository<Entity: PersistentModel>: CRUDRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func fetchAll() async throws -> [Entity] {
        try context.fetch(FetchDescriptor<Entity>())
    }

    public func save(_ entity: Entity) async throws {
        context.insert(entity)
        try context.save()
    }

    public func delete(_ entity: Entity) async throws {
        context.delete(entity)
        try context.save()
    }
}
