public protocol CRUDRepository: Sendable {
    associatedtype Entity
    func fetchAll() async throws -> [Entity]
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
}
