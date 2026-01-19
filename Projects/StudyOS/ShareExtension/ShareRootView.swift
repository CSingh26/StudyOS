import Core
import Storage
import SwiftData
import SwiftUI
import UIComponents

struct ShareRootView: View {
    private let extensionContext: NSExtensionContext?
    @StateObject private var viewModel: ShareViewModel

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        _viewModel = StateObject(wrappedValue: ShareViewModel(extensionContext: extensionContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let item = viewModel.shareItem {
                    StudyCard {
                        VStack(alignment: .leading, spacing: 8) {
                            StudyText("Save to StudyOS", style: .headline)
                            StudyText(item.title, style: .body, color: StudyColor.secondaryText)
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Profile", style: .headline)
                        Picker("Profile", selection: $viewModel.selectedProfileId) {
                            ForEach(viewModel.profiles) { profile in
                                Text(profile.name).tag(UUID?.some(profile.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Course", style: .headline)
                        Picker("Course", selection: $viewModel.selectedCourseId) {
                            ForEach(viewModel.courses) { course in
                                Text(course.name).tag(UUID?.some(course.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Attach to assignment", style: .headline)
                        Picker("Assignment", selection: $viewModel.selectedAssignmentId) {
                            Text("None").tag(UUID?.none)
                            ForEach(viewModel.assignmentsForSelectedCourse) { assignment in
                                Text(assignment.title).tag(UUID?.some(assignment.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if let status = viewModel.statusMessage {
                    StudyText(status, style: .caption, color: StudyColor.secondaryText)
                }

                StudyButton(viewModel.isSaving ? "Saving..." : "Save") {
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.isSaving || viewModel.selectedCourseId == nil)

                Button("Cancel") {
                    viewModel.cancel()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .navigationTitle("Share")
        }
        .onAppear {
            viewModel.load()
        }
        .environment(\.modelContext, viewModel.modelContext)
    }
}
