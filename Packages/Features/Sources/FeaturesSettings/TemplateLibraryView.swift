import Features
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct TemplateLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Template.title) private var templates: [Template]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var newTitle: String = ""
    @State private var newKind: TemplateKind = .other
    @State private var newSteps: String = ""

    public init() {}

    public var body: some View {
        List {
            Section("Templates") {
                ForEach(templates) { template in
                    NavigationLink(template.title) {
                        TemplateDetailView(template: template)
                    }
                }
            }

            Section("Create Template") {
                TextField("Template name", text: $newTitle)
                Picker("Type", selection: $newKind) {
                    ForEach(TemplateKind.allCases, id: \.self) { kind in
                        Text(kindTitle(kind)).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                TextEditor(text: $newSteps)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(StudyColor.divider, lineWidth: 1)
                    )
                Button("Add Template") {
                    createTemplate()
                }
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Templates")
    }

    private var activeProfile: Profile? {
        guard let activeId = profileSession.activeProfileId else { return profiles.first }
        return profiles.first { $0.id == activeId }
    }

    private func createTemplate() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let template = Template(title: trimmed, kind: newKind, defaultMinutes: 30, profile: activeProfile)
        modelContext.insert(template)

        let steps = newSteps.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for (index, step) in steps.enumerated() where !step.isEmpty {
            let subtask = Subtask(title: step, isCompleted: false, estimatedMinutes: 20, orderIndex: index, template: template)
            modelContext.insert(subtask)
        }

        newTitle = ""
        newSteps = ""
        try? modelContext.save()
    }

    private func kindTitle(_ kind: TemplateKind) -> String {
        switch kind {
        case .reading: return "Reading"
        case .writing: return "Writing"
        case .coding: return "Coding"
        case .problemSet: return "Problem set"
        case .project: return "Project"
        case .exam: return "Exam"
        case .quiz: return "Quiz"
        case .other: return "Other"
        }
    }
}
