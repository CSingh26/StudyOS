import Core
import Features
import Storage
import SwiftData
import SwiftUI

@main
struct StudyOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var profileSession = ProfileSession(appGroupId: AppConstants.appGroupId)
    private let container: ModelContainer

    init() {
        let configuration = StorageConfiguration(
            appGroupId: AppConstants.appGroupId,
            cloudKitContainerId: AppConstants.cloudKitContainerId,
            useCloudKit: false
        )
        container = try! StorageController.makeContainer(models: StorageModels.all, configuration: configuration)
        BackgroundSyncManager.shared.configure(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileSession)
        }
        .modelContainer(container)
    }
}
