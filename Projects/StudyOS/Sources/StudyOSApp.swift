import Core
import Features
import Storage
import SwiftData
import SwiftUI

@main
struct StudyOSApp: App {
    @StateObject private var profileSession = ProfileSession(appGroupId: AppConstants.appGroupId)
    private let container: ModelContainer

    init() {
        let configuration = StorageConfiguration(
            appGroupId: AppConstants.appGroupId,
            cloudKitContainerId: AppConstants.cloudKitContainerId,
            useCloudKit: false
        )
        container = try! StorageController.makeContainer(models: StorageModels.all, configuration: configuration)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileSession)
        }
        .modelContainer(container)
    }
}
