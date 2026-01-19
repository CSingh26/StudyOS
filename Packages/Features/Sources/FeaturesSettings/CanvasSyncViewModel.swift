import Storage
import SwiftData
import SwiftUI

@MainActor
final class CanvasSyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var lastError: String?
    @Published var report: CanvasSyncReport?

    func sync(profile: Profile, context: ModelContext) async {
        guard let engine = CanvasSyncEngine(context: context, profile: profile) else {
            lastError = "Canvas configuration incomplete."
            return
        }
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            let result = try await engine.syncAll()
            report = result
        } catch {
            lastError = error.localizedDescription
            profile.lastCanvasSyncError = lastError
            try? context.save()
        }
    }
}
