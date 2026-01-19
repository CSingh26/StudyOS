import Storage
import SwiftData
import SwiftUI
import UIComponents

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @Query(sort: \Assignment.title) private var assignments: [Assignment]
    @Query(sort: \Subtask.title) private var subtasks: [Subtask]
    @Query(sort: \NoteItem.createdAt) private var notes: [NoteItem]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Search courses, tasks, and notes", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Search")
                    .padding(.horizontal)

                if query.isEmpty {
                    EmptyStateView(
                        title: "Start searching",
                        message: "Look up assignments, notes, or files across StudyOS."
                    )
                } else {
                    List {
                        if !assignmentResults.isEmpty {
                            Section("Assignments") {
                                ForEach(assignmentResults) { assignment in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(assignment.title)
                                            .font(StudyTypography.body)
                                        Text(assignment.course?.name ?? "")
                                            .font(StudyTypography.caption)
                                            .foregroundColor(StudyColor.secondaryText)
                                    }
                                }
                            }
                        }

                        if !subtaskResults.isEmpty {
                            Section("Subtasks") {
                                ForEach(subtaskResults) { subtask in
                                    Text(subtask.title)
                                        .font(StudyTypography.body)
                                }
                            }
                        }

                        if !noteResults.isEmpty {
                            Section("Notes") {
                                ForEach(noteResults) { note in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title)
                                            .font(StudyTypography.body)
                                        Text(notePreview(note))
                                            .font(StudyTypography.caption)
                                            .foregroundColor(StudyColor.secondaryText)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }

                        if assignmentResults.isEmpty && subtaskResults.isEmpty && noteResults.isEmpty {
                            EmptyStateView(
                                title: "No results",
                                message: "Try a different keyword."
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .padding(.top, 24)
            .background(StudyColor.background)
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var assignmentResults: [Assignment] {
        let needle = query.lowercased()
        return assignments.filter { assignment in
            assignment.title.lowercased().contains(needle)
                || assignment.details.lowercased().contains(needle)
                || (assignment.course?.name.lowercased().contains(needle) ?? false)
        }
    }

    private var subtaskResults: [Subtask] {
        let needle = query.lowercased()
        return subtasks.filter { $0.title.lowercased().contains(needle) }
    }

    private var noteResults: [NoteItem] {
        let needle = query.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(needle)
                || $0.content.lowercased().contains(needle)
                || $0.ocrText.lowercased().contains(needle)
        }
    }

    private func notePreview(_ note: NoteItem) -> String {
        if !note.content.isEmpty { return note.content }
        return note.ocrText
    }
}
