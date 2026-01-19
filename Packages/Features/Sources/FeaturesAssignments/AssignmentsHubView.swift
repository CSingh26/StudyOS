import Core
import Planner
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct AssignmentsHubView: View {
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \CalendarEvent.startDate) private var calendarEvents: [CalendarEvent]
    @Query(sort: \StudyBlock.startDate) private var studyBlocks: [StudyBlock]

    @State private var selectedFilter: AssignmentFilter = .dueSoon
    @State private var selectedSort: AssignmentSort = .priority
    @State private var selectedStatus: StatusFilter = .all
    @State private var selectedCourseId: UUID?
    @State private var viewMode: ViewMode = .list
    @AppStorage(AppConstants.priorityDueSoonKey) private var dueSoonWeight: Double = 0.35
    @AppStorage(AppConstants.priorityEffortKey) private var effortWeight: Double = 0.2
    @AppStorage(AppConstants.priorityWeightKey) private var weightWeight: Double = 0.25
    @AppStorage(AppConstants.priorityStatusKey) private var statusWeight: Double = 0.1
    @AppStorage(AppConstants.priorityCourseKey) private var courseWeight: Double = 0.1

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker("Filter", selection: $selectedFilter) {
                ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if selectedFilter == .byCourse {
                Picker("Course", selection: $selectedCourseId) {
                    Text("All").tag(UUID?.none)
                    ForEach(courses) { course in
                        Text(course.name).tag(UUID?.some(course.id))
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Menu {
                    ForEach(AssignmentSort.allCases, id: \.self) { sort in
                        Button(sort.title) {
                            selectedSort = sort
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(StudyTypography.caption)
                }
            }

            if viewMode == .list {
                listView
            } else {
                AssignmentCalendarView(
                    assignments: filteredAssignments,
                    calendarEvents: calendarEvents,
                    studyBlocks: studyBlocks
                )
            }
        }
        .padding(16)
    }

    private var listView: some View {
        Group {
            if sortedAssignments.isEmpty {
                EmptyStateView(title: "No assignments", message: "Sync Canvas or add tasks to get started.")
            } else {
                List {
                    ForEach(sortedAssignments) { assignment in
                        NavigationLink {
                            AssignmentDetailView(assignment: assignment)
                        } label: {
                            AssignmentRowView(assignment: assignment)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var filteredAssignments: [Assignment] {
        let statusFiltered = assignments.filter { assignment in
            switch selectedStatus {
            case .all:
                return true
            case .notStarted:
                return assignment.status == .notStarted
            case .inProgress:
                return assignment.status == .inProgress
            case .submitted:
                return assignment.status == .submitted
            }
        }

        switch selectedFilter {
        case .all:
            return statusFiltered
        case .dueSoon:
            let soon = Date().addingTimeInterval(7 * 24 * 60 * 60)
            return statusFiltered.filter { ($0.dueDate ?? .distantFuture) <= soon }
        case .highEffort:
            return statusFiltered.filter { $0.estimatedMinutes >= 90 }
        case .highWeight:
            return statusFiltered.filter { $0.weight >= 10 }
        case .byCourse:
            guard let courseId = selectedCourseId else { return statusFiltered }
            return statusFiltered.filter { $0.course?.id == courseId }
        }
    }

    private var sortedAssignments: [Assignment] {
        switch selectedSort {
        case .priority:
            return filteredAssignments.sorted { priorityScore($0) > priorityScore($1) }
        case .dueDate:
            return filteredAssignments.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .effort:
            return filteredAssignments.sorted { $0.estimatedMinutes > $1.estimatedMinutes }
        }
    }

    private func priorityScore(_ assignment: Assignment) -> Double {
        let weights = PriorityWeights(
            dueSoonFactor: dueSoonWeight,
            effortFactor: effortWeight,
            weightFactor: weightWeight,
            statusFactor: statusWeight,
            courseImportance: courseWeight
        )
        let task = StudyTask(
            title: assignment.title,
            dueDate: assignment.dueDate,
            estimatedMinutes: assignment.estimatedMinutes,
            type: .other,
            courseId: assignment.course?.id,
            weight: assignment.weight,
            status: taskStatus(from: assignment.status),
            courseImportance: 0.5
        )
        return PriorityScorer.score(task: task, weights: weights)
    }

    private func taskStatus(from status: AssignmentStatus) -> StudyTaskStatus {
        switch status {
        case .notStarted:
            return .notStarted
        case .inProgress:
            return .inProgress
        case .submitted:
            return .completed
        }
    }
}

private enum AssignmentFilter: CaseIterable {
    case all
    case dueSoon
    case highEffort
    case highWeight
    case byCourse

    var title: String {
        switch self {
        case .all: return "All"
        case .dueSoon: return "Due soon"
        case .highEffort: return "High effort"
        case .highWeight: return "High weight"
        case .byCourse: return "Course"
        }
    }
}

private enum AssignmentSort: CaseIterable {
    case priority
    case dueDate
    case effort

    var title: String {
        switch self {
        case .priority: return "Priority"
        case .dueDate: return "Due date"
        case .effort: return "Effort"
        }
    }
}

private enum StatusFilter: CaseIterable {
    case all
    case notStarted
    case inProgress
    case submitted

    var title: String {
        switch self {
        case .all: return "All status"
        case .notStarted: return "Not started"
        case .inProgress: return "In progress"
        case .submitted: return "Submitted"
        }
    }
}

private enum ViewMode: CaseIterable {
    case list
    case calendar

    var title: String {
        switch self {
        case .list: return "List"
        case .calendar: return "Calendar"
        }
    }
}

private struct AssignmentRowView: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(assignment.title)
                .font(StudyTypography.headline)
            if let dueDate = assignment.dueDate {
                Text("Due \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(StudyTypography.caption)
                    .foregroundColor(StudyColor.secondaryText)
            }
            HStack(spacing: 8) {
                if let courseName = assignment.course?.name {
                    StudyChip(text: courseName, color: StudyColor.coolAccent)
                }
                StudyChip(text: statusTitle(for: assignment.status), color: StudyColor.warmAccent)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statusTitle(for status: AssignmentStatus) -> String {
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
