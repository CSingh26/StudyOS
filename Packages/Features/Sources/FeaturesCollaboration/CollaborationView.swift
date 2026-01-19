import CloudKit
import Core
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct CollaborationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroupProject.createdAt) private var projects: [GroupProject]
    @Query(sort: \AvailabilityBlock.startDate) private var availability: [AvailabilityBlock]

    @StateObject private var viewModel = CollaborationViewModel()

    public init() {}

    public var body: some View {
        List {
            if !viewModel.iCloudAvailable {
                Section {
                    StudyText("iCloud is not available. Collaboration will stay local.", style: .caption, color: StudyColor.secondaryText)
                }
            }

            Section("Availability") {
                ForEach(availability) { block in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(StudyTypography.body)
                        Text(block.endDate.formatted(date: .abbreviated, time: .shortened))
                            .font(StudyTypography.caption)
                            .foregroundColor(StudyColor.secondaryText)
                    }
                }

                Button("Add Availability") {
                    viewModel.showAvailabilityForm = true
                }
            }

            Section("Group Projects") {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project, store: viewModel.store)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title)
                                .font(StudyTypography.headline)
                            Text("Milestones: \(project.milestones.count)")
                                .font(StudyTypography.caption)
                                .foregroundColor(StudyColor.secondaryText)
                        }
                    }
                }

                Button("Create Group Project") {
                    viewModel.showProjectForm = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $viewModel.showAvailabilityForm) {
            AvailabilityForm { start, end in
                viewModel.addAvailability(start: start, end: end, context: modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showProjectForm) {
            ProjectForm { title, notes in
                viewModel.addProject(title: title, notes: notes, context: modelContext)
            }
        }
        .task {
            await viewModel.checkAvailability()
        }
    }
}

private struct AvailabilityForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)

    let onSave: (Date, Date) -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start", selection: $startDate)
                DatePicker("End", selection: $endDate)
            }
            .navigationTitle("Availability")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(startDate, endDate)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ProjectForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""

    let onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(title, notes)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: GroupProject
    let store: CollaborationStore

    @State private var newMilestoneTitle: String = ""
    @State private var newMilestoneDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var activeShare: CKShare?
    @State private var showShareSheet = false

    var body: some View {
        List {
            Section("Project") {
                TextField("Title", text: $project.title)
                TextEditor(text: $project.notes)
                    .frame(minHeight: 100)
            }

            Section("Milestones") {
                ForEach(project.milestones) { milestone in
                    HStack {
                        Text(milestone.title)
                        Spacer()
                        Text(milestone.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(StudyTypography.caption)
                            .foregroundColor(StudyColor.secondaryText)
                    }
                }
                HStack {
                    TextField("Milestone title", text: $newMilestoneTitle)
                    DatePicker("Due", selection: $newMilestoneDate, displayedComponents: .date)
                }
                Button("Add Milestone") {
                    addMilestone()
                }
                .disabled(newMilestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Share") {
                Button("Share Project") {
                    Task {
                        activeShare = try? await store.createShare(for: project)
                        showShareSheet = activeShare != nil
                    }
                }
            }
        }
        .navigationTitle(project.title)
        .sheet(isPresented: $showShareSheet) {
            if let share = activeShare {
                CloudShareView(share: share)
            }
        }
    }

    private func addMilestone() {
        let milestone = Milestone(
            title: newMilestoneTitle,
            dueDate: newMilestoneDate,
            isCompleted: false,
            groupProject: project
        )
        modelContext.insert(milestone)
        try? modelContext.save()
        Task { try? await store.saveMilestone(milestone, project: project) }
        newMilestoneTitle = ""
    }
}

private struct CloudShareView: UIViewControllerRepresentable {
    let share: CKShare

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: CKContainer(identifier: AppConstants.cloudKitContainerId))
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}

@MainActor
final class CollaborationViewModel: ObservableObject {
    @Published var showAvailabilityForm = false
    @Published var showProjectForm = false
    @Published var iCloudAvailable = true

    let store: CollaborationStore

    init() {
        store = CloudKitCollaborationStore(containerId: AppConstants.cloudKitContainerId)
    }

    func checkAvailability() async {
        do {
            let status = try await CKContainer(identifier: AppConstants.cloudKitContainerId).accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }
    }

    func addAvailability(start: Date, end: Date, context: ModelContext) {
        let block = AvailabilityBlock(startDate: start, endDate: end)
        context.insert(block)
        try? context.save()
        if iCloudAvailable {
            Task { try? await store.saveAvailability(block) }
        }
    }

    func addProject(title: String, notes: String, context: ModelContext) {
        let project = GroupProject(title: title, notes: notes, createdAt: Date())
        context.insert(project)
        try? context.save()
        if iCloudAvailable {
            Task { try? await store.saveGroupProject(project) }
        }
    }
}
