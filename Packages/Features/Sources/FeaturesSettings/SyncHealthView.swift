import Features
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct SyncHealthView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @StateObject private var viewModel = CanvasSyncViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            StudyCard {
                VStack(alignment: .leading, spacing: 12) {
                    StudyText("Canvas Sync", style: .headline)
                    if let lastSync = activeProfile?.lastCanvasSyncAt {
                        StudyText("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))", style: .caption, color: StudyColor.secondaryText)
                    } else {
                        StudyText("No sync history yet.", style: .caption, color: StudyColor.secondaryText)
                    }
                    if let error = activeProfile?.lastCanvasSyncError {
                        StudyText("Last error: \(error)", style: .caption, color: StudyColor.secondaryText)
                    }
                }
            }

            if let report = viewModel.report {
                StudyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        StudyText("Items synced", style: .headline)
                        StudyText("Courses: \(report.courses)", style: .body)
                        StudyText("Assignments: \(report.assignments)", style: .body)
                        StudyText("Quizzes: \(report.quizzes)", style: .body)
                        StudyText("Announcements: \(report.announcements)", style: .body)
                        StudyText("Grades: \(report.grades)", style: .body)
                        StudyText("Calendar events: \(report.calendarEvents)", style: .body)
                    }
                }
            }

            if let error = viewModel.lastError {
                StudyCard {
                    StudyText(error, style: .caption, color: StudyColor.secondaryText)
                }
            }

            StudyButton(viewModel.isSyncing ? "Syncing..." : "Sync Now") {
                Task {
                    if let profile = activeProfile {
                        await viewModel.sync(profile: profile, context: modelContext)
                    }
                }
            }
            .disabled(viewModel.isSyncing)

            Spacer()
        }
        .padding(16)
        .navigationTitle("Sync Health")
    }

    private var activeProfile: Profile? {
        guard let activeId = profileSession.activeProfileId else { return profiles.first }
        return profiles.first { $0.id == activeId }
    }
}
