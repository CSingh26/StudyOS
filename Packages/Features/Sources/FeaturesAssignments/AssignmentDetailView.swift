import Core
import Planner
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct AssignmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Template.title) private var templates: [Template]
    @Bindable private var assignment: Assignment
    @State private var summary: AssignmentSummary?
    @State private var selectedTemplateKind: TemplateKind = .other
    @State private var selectedTemplateId: UUID?

    public init(assignment: Assignment) {
        self.assignment = assignment
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let summary {
                    StudyCard {
                        VStack(alignment: .leading, spacing: 8) {
                            StudyText("Summary", style: .headline)
                            if !summary.whatToDo.isEmpty {
                                StudyText(summary.whatToDo.joined(separator: " "), style: .body, color: StudyColor.secondaryText)
                            }
                            if !summary.deliverables.isEmpty {
                                StudyText("Deliverables: \(summary.deliverables.joined(separator: "; "))", style: .caption, color: StudyColor.secondaryText)
                            }
                            if !summary.constraints.isEmpty {
                                StudyText("Constraints: \(summary.constraints.joined(separator: "; "))", style: .caption, color: StudyColor.secondaryText)
                            }
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        StudyText(assignment.title, style: .headline)
                        if let dueDate = assignment.dueDate {
                            StudyText("Due \(dueDate.formatted(date: .abbreviated, time: .shortened))", style: .caption, color: StudyColor.secondaryText)
                        }
                        if !assignment.details.isEmpty {
                            StudyText(assignment.details, style: .body, color: StudyColor.secondaryText)
                        }
                        if let external = assignment.externalURL, let url = URL(string: external) {
                            Link("Open in Canvas", destination: url)
                                .font(StudyTypography.caption)
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Status", style: .headline)
                        Picker("Status", selection: $assignment.status) {
                            ForEach(AssignmentStatus.allCases, id: \.self) { status in
                                Text(statusTitle(status)).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                        StudyText("Estimated time: \(assignment.estimatedMinutes) min", style: .caption, color: StudyColor.secondaryText)
                        if !assignment.submissionType.isEmpty {
                            StudyText("Submission: \(assignment.submissionType)", style: .caption, color: StudyColor.secondaryText)
                        }
                        if assignment.weight > 0 {
                            StudyText("Weight: \(assignment.weight, format: .number) pts", style: .caption, color: StudyColor.secondaryText)
                        }
                    }
                }

                if !assignment.subtasks.isEmpty {
                    StudyCard {
                        VStack(alignment: .leading, spacing: 8) {
                            StudyText("Subtasks", style: .headline)
                            ForEach(assignment.subtasks) { subtask in
                                SubtaskRow(subtask: subtask)
                            }
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Task breakdown", style: .headline)
                        Picker("Template", selection: $selectedTemplateKind) {
                            ForEach(TemplateKind.allCases, id: \.self) { kind in
                                Text(kindTitle(kind)).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)

                        if !matchingTemplates.isEmpty {
                            Picker("Custom template", selection: $selectedTemplateId) {
                                Text("Default").tag(UUID?.none)
                                ForEach(matchingTemplates) { template in
                                    Text(template.title).tag(UUID?.some(template.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Button("Generate subtasks") {
                            generateSubtasks()
                        }
                        .buttonStyle(.bordered)
                        StudyText("Templates can be customized in Settings.", style: .caption, color: StudyColor.secondaryText)
                    }
                }

                if !assignment.focusSessions.isEmpty {
                    StudyCard {
                        VStack(alignment: .leading, spacing: 8) {
                            StudyText("Focus sessions", style: .headline)
                            ForEach(assignment.focusSessions) { session in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(session.durationMinutes) min")
                                        .font(StudyTypography.body)
                                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(StudyTypography.caption)
                                        .foregroundColor(StudyColor.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Assignment")
        .onAppear {
            selectedTemplateKind = inferredTemplateKind()
            selectedTemplateId = matchingTemplates.first?.id
            if !assignment.details.isEmpty {
                summary = DeterministicSummarizer.summarize(text: assignment.details)
            }
        }
    }

    private func statusTitle(_ status: AssignmentStatus) -> String {
        switch status {
        case .notStarted:
            return "Not started"
        case .inProgress:
            return "In progress"
        case .submitted:
            return "Submitted"
        }
    }

    private var matchingTemplates: [Template] {
        templates.filter { $0.kind == selectedTemplateKind }
    }

    private func inferredTemplateKind() -> TemplateKind {
        let lower = assignment.submissionType.lowercased()
        if lower.contains("code") || lower.contains("online") {
            return .coding
        }
        if lower.contains("essay") || lower.contains("paper") {
            return .writing
        }
        if lower.contains("quiz") {
            return .quiz
        }
        if lower.contains("exam") {
            return .exam
        }
        return .other
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

    private func generateSubtasks() {
        let steps: [TaskTemplateStep]
        if let templateId = selectedTemplateId,
           let template = matchingTemplates.first(where: { $0.id == templateId }) {
            steps = template.subtasks.sorted(by: { $0.orderIndex < $1.orderIndex }).map {
                TaskTemplateStep(title: $0.title, estimatedMinutes: $0.estimatedMinutes)
            }
        } else {
            steps = TaskTemplateEngine.steps(for: taskType(from: selectedTemplateKind))
        }

        for (index, step) in steps.enumerated() {
            let exists = assignment.subtasks.contains { $0.title == step.title }
            guard !exists else { continue }
            let subtask = Subtask(
                title: step.title,
                isCompleted: false,
                estimatedMinutes: step.estimatedMinutes,
                orderIndex: assignment.subtasks.count + index,
                assignment: assignment
            )
            modelContext.insert(subtask)
        }
        try? modelContext.save()
    }

    private func taskType(from kind: TemplateKind) -> TaskType {
        switch kind {
        case .reading: return .reading
        case .writing: return .writing
        case .coding: return .coding
        case .problemSet: return .problemSet
        case .project: return .project
        case .exam: return .exam
        case .quiz: return .quiz
        case .other: return .other
        }
    }
}

private struct SubtaskRow: View {
    @Bindable var subtask: Subtask

    var body: some View {
        HStack {
            Button {
                subtask.isCompleted.toggle()
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? StudyColor.coolAccent : StudyColor.secondaryText)
            }
            TextField("Subtask", text: $subtask.title)
                .textFieldStyle(.roundedBorder)
        }
    }
}
