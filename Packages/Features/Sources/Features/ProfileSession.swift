import Core
import Foundation

@MainActor
public final class ProfileSession: ObservableObject {
    @Published public private(set) var activeProfileId: UUID?

    private let defaults: UserDefaults

    public init(appGroupId: String) {
        self.defaults = UserDefaults(suiteName: appGroupId) ?? .standard
        load()
    }

    public func load() {
        guard let value = defaults.string(forKey: AppConstants.activeProfileKey),
              let id = UUID(uuidString: value) else {
            activeProfileId = nil
            return
        }
        activeProfileId = id
    }

    public func select(profileId: UUID) {
        activeProfileId = profileId
        defaults.set(profileId.uuidString, forKey: AppConstants.activeProfileKey)
    }

    public func clear() {
        activeProfileId = nil
        defaults.removeObject(forKey: AppConstants.activeProfileKey)
    }
}
