import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct AssignmentDetailView: View {
    @Bindable private var assignment: Assignment

    public init(assignment: Assignment) {
        self.assignment = assignment
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                                HStack {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? StudyColor.coolAccent : StudyColor.secondaryText)
                                    Text(subtask.title)
                                        .font(StudyTypography.body)
                                }
                            }
                        }
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
}
