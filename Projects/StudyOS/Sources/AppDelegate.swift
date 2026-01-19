import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundSyncManager.shared.register()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundSyncManager.shared.schedule()
    }
}
