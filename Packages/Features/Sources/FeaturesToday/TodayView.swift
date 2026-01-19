import Core
import Planner
import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    @Query(sort: \StudyBlock.startDate) private var studyBlocks: [StudyBlock]
    @Query(sort: \FocusSession.startedAt) private var focusSessions: [FocusSession]
    @Query(sort: \Course.name) private var courses: [Course]

    @State private var selectedAssignment: Assignment?
    @State private var showFocus = false

    @AppStorage(AppConstants.priorityDueSoonKey) private var dueSoonWeight: Double = 0.35
    @AppStorage(AppConstants.priorityEffortKey) private var effortWeight: Double = 0.2
    @AppStorage(AppConstants.priorityWeightKey) private var weightWeight: Double = 0.25
    @AppStorage(AppConstants.priorityStatusKey) private var statusWeight: Double = 0.1
    @AppStorage(AppConstants.priorityCourseKey) private var courseWeight: Double = 0.1

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        StudyText("Top priorities", style: .headline)
                        ForEach(topPriorities) { assignment in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assignment.title)
                                        .font(StudyTypography.body)
                                    if let due = assignment.dueDate {
                                        Text("Due \(due.formatted(date: .abbreviated, time: .shortened))")
                                            .font(StudyTypography.caption)
                                            .foregroundColor(StudyColor.secondaryText)
                                    }
                                }
                                Spacer()
                                Button("Start") {
                                    startFocus(for: assignment)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Scheduled blocks", style: .headline)
                        let todayBlocks = studyBlocks.filter { Calendar.current.isDateInToday($0.startDate) }
                        if todayBlocks.isEmpty {
                            StudyText("No study blocks scheduled today.", style: .caption, color: StudyColor.secondaryText)
                        }
                        ForEach(todayBlocks) { block in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(block.assignment?.title ?? "Study block")
                                        .font(StudyTypography.body)
                                    Text(block.startDate.formatted(date: .omitted, time: .shortened))
                                        .font(StudyTypography.caption)
                                        .foregroundColor(StudyColor.secondaryText)
                                }
                                Spacer()
                                Button("Snooze") {
                                    snooze(block)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Workload", style: .headline)
                        WorkloadHeatmapView(blocks: studyBlocks, deadlines: assignments.compactMap { $0.dueDate })
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("Weekly stats", style: .headline)
                        StudyText("Focus minutes: \(weeklyFocusMinutes)", style: .body)
                        StudyText("Assignments completed: \(completedAssignmentsCount)", style: .body)
                        if !focusMinutesByCourse.isEmpty {
                            ForEach(focusMinutesByCourse.keys.sorted(), id: \.self) { key in
                                if let minutes = focusMinutesByCourse[key] {
                                    StudyText("\(key): \(minutes) min", style: .caption, color: StudyColor.secondaryText)
                                }
                            }
                        }
                    }
                }

                StudyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StudyText("All assignments", style: .headline)
                        ForEach(assignments) { assignment in
                            HStack {
                                Text(assignment.title)
                                    .font(StudyTypography.body)
                                Spacer()
                                Text(statusTitle(for: assignment.status))
                                    .font(StudyTypography.caption)
                                    .foregroundColor(StudyColor.secondaryText)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showFocus) {
            if let assignment = selectedAssignment {
                FocusSessionSheet(assignment: assignment) { minutes in
                    logFocus(minutes: minutes, assignment: assignment)
                }
            }
        }
    }

    private var topPriorities: [Assignment] {
        let weights = PriorityWeights(
            dueSoonFactor: dueSoonWeight,
            effortFactor: effortWeight,
            weightFactor: weightWeight,
            statusFactor: statusWeight,
            courseImportance: courseWeight
        )
        let scored = assignments.map { assignment -> (Assignment, Double) in
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
            return (assignment, PriorityScorer.score(task: task, weights: weights))
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(3).map { $0.0 }
    }

    private var weeklyFocusMinutes: Int {
        focusSessions.filter { isInLastWeek($0.startedAt) }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    private var completedAssignmentsCount: Int {
        assignments.filter { $0.status == .submitted }.count
    }

    private var focusMinutesByCourse: [String: Int] {
        var totals: [String: Int] = [:]
        for session in focusSessions where isInLastWeek(session.startedAt) {
            let courseName = session.course?.name ?? "General"
            totals[courseName, default: 0] += session.durationMinutes
        }
        return totals
    }

    private func startFocus(for assignment: Assignment) {
        selectedAssignment = assignment
        Haptics.impact(style: .medium)
        withAnimation(.easeInOut(duration: 0.2)) {
            showFocus = true
        }
    }

    private func snooze(_ block: StudyBlock) {
        let newStart = block.startDate.addingTimeInterval(15 * 60)
        let duration = block.endDate.timeIntervalSince(block.startDate)
        block.startDate = newStart
        block.endDate = newStart.addingTimeInterval(duration)
        try? modelContext.save()
        Haptics.impact(style: .light)
    }

    private func logFocus(minutes: Int, assignment: Assignment) {
        let session = FocusSession(
            startedAt: Date(),
            durationMinutes: minutes,
            notes: "",
            assignment: assignment,
            course: assignment.course,
            taskType: .other
        )
        modelContext.insert(session)
        try? modelContext.save()
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

    private func isInLastWeek(_ date: Date) -> Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        return date >= weekAgo
    }
}
