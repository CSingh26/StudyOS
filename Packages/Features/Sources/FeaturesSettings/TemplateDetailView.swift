import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable private var template: Template
    @State private var newStepTitle: String = ""

    public init(template: Template) {
        self.template = template
    }

    public var body: some View {
        List {
            Section("Template") {
                TextField("Name", text: $template.title)
                Picker("Type", selection: $template.kind) {
                    ForEach(TemplateKind.allCases, id: \.self) { kind in
                        Text(kindTitle(kind)).tag(kind)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Steps") {
                ForEach(template.subtasks.sorted(by: { $0.orderIndex < $1.orderIndex })) { subtask in
                    TemplateStepRow(subtask: subtask)
                }
                .onDelete(perform: deleteSteps)

                HStack {
                    TextField("New step", text: $newStepTitle)
                    Button("Add") {
                        addStep()
                    }
                    .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle("Template")
    }

    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let order = template.subtasks.count
        let subtask = Subtask(title: trimmed, isCompleted: false, estimatedMinutes: 20, orderIndex: order, template: template)
        modelContext.insert(subtask)
        newStepTitle = ""
        try? modelContext.save()
    }

    private func deleteSteps(at offsets: IndexSet) {
        let sorted = template.subtasks.sorted(by: { $0.orderIndex < $1.orderIndex })
        for index in offsets {
            let step = sorted[index]
            modelContext.delete(step)
        }
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

private struct TemplateStepRow: View {
    @Bindable var subtask: Subtask

    var body: some View {
        HStack {
            TextField("Step", text: $subtask.title)
            Spacer()
            Text("\(subtask.estimatedMinutes) min")
                .font(StudyTypography.caption)
                .foregroundColor(StudyColor.secondaryText)
        }
    }
}
