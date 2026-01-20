import BackgroundTasks
import Core
import FeaturesSettings
import Storage
import SwiftData

final class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()

    private var container: ModelContainer?

    private init() {}

    func configure(container: ModelContainer) {
        self.container = container
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConstants.backgroundRefreshId, using: nil) { task in
            self.handleRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConstants.backgroundProcessingId, using: nil) { task in
            self.handleProcessing(task: task as! BGProcessingTask)
        }
    }

    func schedule() {
        let refresh = BGAppRefreshTaskRequest(identifier: AppConstants.backgroundRefreshId)
        refresh.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30)
        try? BGTaskScheduler.shared.submit(refresh)

        let processing = BGProcessingTaskRequest(identifier: AppConstants.backgroundProcessingId)
        processing.requiresNetworkConnectivity = true
        processing.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        try? BGTaskScheduler.shared.submit(processing)
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        schedule()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            let success = await performCanvasSync()
            task.setTaskCompleted(success: success)
        }
    }

    private func handleProcessing(task: BGProcessingTask) {
        schedule()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            let success = await performCanvasSync()
            task.setTaskCompleted(success: success)
        }
    }

    private func performCanvasSync() async -> Bool {
        guard let container else { return false }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Profile>(predicate: #Predicate { $0.activeProfile == true })
        guard let profile = try? context.fetch(descriptor).first else {
            return false
        }
        guard profile.canvasLimitedMode == false else { return true }
        let engine = await MainActor.run {
            CanvasSyncEngine(context: context, profile: profile)
        }
        guard let engine else {
            return false
        }
        do {
            try await engine.syncAll()
            return true
        } catch {
            profile.lastCanvasSyncError = error.localizedDescription
            try? context.save()
            return false
        }
    }
}
