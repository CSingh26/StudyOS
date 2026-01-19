import Core
import MapKit
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
    @Query(sort: \CalendarEvent.startDate) private var calendarEvents: [CalendarEvent]

    @State private var selectedAssignment: Assignment?
    @State private var showFocus = false
    @State private var isPlanning = false
    @State private var planningStatus: String?

    @AppStorage(AppConstants.priorityDueSoonKey) private var dueSoonWeight: Double = 0.35
    @AppStorage(AppConstants.priorityEffortKey) private var effortWeight: Double = 0.2
    @AppStorage(AppConstants.priorityWeightKey) private var weightWeight: Double = 0.25
    @AppStorage(AppConstants.priorityStatusKey) private var statusWeight: Double = 0.1
    @AppStorage(AppConstants.priorityCourseKey) private var courseWeight: Double = 0.1
    @AppStorage(AppConstants.plannerExportCalendarKey) private var exportCalendarEnabled: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let nextEvent = nextClassEvent {
                    StudyCard {
                        VStack(alignment: .leading, spacing: 8) {
                            StudyText("Next class", style: .headline)
                            StudyText(nextEvent.title, style: .body)
                            StudyText(nextEvent.startDate.formatted(date: .abbreviated, time: .shortened), style: .caption, color: StudyColor.secondaryText)
                            if !nextEvent.location.isEmpty {
                                StudyText(nextEvent.location, style: .caption, color: StudyColor.secondaryText)
                            }
                            Button("Open in Maps") {
                                openInMaps(nextEvent)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

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
                        StudyText("Plan", style: .headline)
                        if isPlanning {
                            HStack(spacing: 8) {
                                ProgressView()
                                StudyText("Planning schedule...", style: .caption, color: StudyColor.secondaryText)
                            }
                        }
                        HStack(spacing: 12) {
                            Button("Auto plan") {
                                Task { await planSchedule(recover: false) }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Recovery mode") {
                                Task { await planSchedule(recover: true) }
                            }
                            .buttonStyle(.bordered)
                        }
                        if let planningStatus {
                            StudyText(planningStatus, style: .caption, color: StudyColor.secondaryText)
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
                                    if block.status == .missed {
                                        Text("Missed")
                                            .font(StudyTypography.caption)
                                            .foregroundColor(StudyColor.warmAccent)
                                    }
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
        .onAppear {
            markMissedBlocks()
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

    private var nextClassEvent: CalendarEvent? {
        let now = Date()
        return calendarEvents.first { $0.startDate > now }
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

    private func openInMaps(_ event: CalendarEvent) {
        guard !event.location.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = event.location
        let search = MKLocalSearch(request: request)
        Task {
            if let response = try? await search.start(), let item = response.mapItems.first {
                item.name = event.title
                item.openInMaps()
            }
        }
    }

    private func markMissedBlocks() {
        let now = Date()
        var didUpdate = false
        for block in studyBlocks where block.startDate < now && block.status == .planned {
            block.status = .missed
            didUpdate = true
        }
        if didUpdate {
            try? modelContext.save()
        }
    }

    private func planSchedule(recover: Bool) async {
        guard !isPlanning else { return }
        isPlanning = true
        planningStatus = nil
        defer { isPlanning = false }

        let activeAssignments = assignments.filter { assignment in
            assignment.status != .submitted
        }
        guard !activeAssignments.isEmpty else {
            planningStatus = "No active assignments to plan."
            return
        }

        let learned = learnedEstimates()
        let tasks = activeAssignments.map { assignment -> StudyTask in
            let taskType = taskType(for: assignment)
            let key = EstimateKey(courseId: assignment.course?.id, taskType: taskType)
            let learnedMinutes = learned[key]
            let estimated = blendEstimate(base: assignment.estimatedMinutes, learned: learnedMinutes)
            return StudyTask(
                id: assignment.id,
                title: assignment.title,
                dueDate: assignment.dueDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedMinutes: max(estimated, 15),
                type: taskType,
                courseId: assignment.course?.id,
                weight: assignment.weight,
                status: taskStatus(from: assignment.status),
                courseImportance: 0.5
            )
        }

        var constraints = PlannerSettingsStore.constraints(from: UserDefaults.standard)
        do {
            let maxDue = tasks.compactMap(\.dueDate).max() ?? Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
            let busyIntervals = try await EventKitBusyIntervalProvider.busyIntervals(
                start: Date(),
                end: maxDue,
                client: DefaultEventKitClient()
            )
            constraints.busyIntervals = busyIntervals
        } catch {
            StudyLogger.planner.error("Failed to load EventKit busy intervals: \(error.localizedDescription)")
        }

        let planner = SimplePlannerEngine()
        let missedBlocks = studyBlocks.filter { $0.startDate < Date() && $0.status == .planned }
        let plannerMissed = missedBlocks.compactMap { block -> Planner.StudyBlock? in
            guard let assignmentId = block.assignment?.id else { return nil }
            return Planner.StudyBlock(taskId: assignmentId, start: block.startDate, end: block.endDate)
        }

        for block in studyBlocks where block.status != .completed {
            modelContext.delete(block)
        }

        do {
            let planned = try await (recover
                ? planner.recover(missedBlocks: plannerMissed, tasks: tasks, constraints: constraints)
                : planner.plan(tasks: tasks, constraints: constraints))
            let assignmentMap = Dictionary(uniqueKeysWithValues: activeAssignments.map { ($0.id, $0) })
            var createdBlocks: [StudyBlock] = []
            for block in planned {
                guard let assignment = assignmentMap[block.taskId] else { continue }
                let studyBlock = StudyBlock(
                    startDate: block.start,
                    endDate: block.end,
                    status: .planned,
                    assignment: assignment,
                    course: assignment.course
                )
                modelContext.insert(studyBlock)
                createdBlocks.append(studyBlock)
            }
            try? modelContext.save()
            if exportCalendarEnabled {
                await StudyBlockCalendarExporter.export(blocks: createdBlocks)
            }
            planningStatus = "Planned \(createdBlocks.count) study blocks."
        } catch {
            StudyLogger.planner.error("Planning failed: \(error.localizedDescription)")
            planningStatus = "Planning failed. Try again."
        }
    }

    private func learnedEstimates() -> [EstimateKey: Double] {
        let records = focusSessions.map { session in
            FocusSessionRecord(
                courseId: session.course?.id,
                taskType: taskType(for: session.taskType),
                durationMinutes: session.durationMinutes
            )
        }
        return TimeEstimateLearner.updateEstimates(current: [:], sessions: records)
    }

    private func blendEstimate(base: Int, learned: Double?) -> Int {
        guard let learned else { return base }
        let blended = (Double(base) * 0.6) + (learned * 0.4)
        return Int(blended.rounded())
    }

    private func taskType(for assignment: Assignment) -> TaskType {
        if let kind = assignment.subtasks.first?.template?.kind {
            return taskType(for: kind)
        }
        let title = assignment.title.lowercased()
        if title.contains("exam") { return .exam }
        if title.contains("quiz") { return .quiz }
        if title.contains("project") { return .project }
        if title.contains("essay") || title.contains("paper") { return .writing }
        if title.contains("lab") || title.contains("problem") { return .problemSet }
        return .other
    }

    private func taskType(for kind: TemplateKind) -> TaskType {
        switch kind {
        case .reading:
            return .reading
        case .writing:
            return .writing
        case .coding:
            return .coding
        case .problemSet:
            return .problemSet
        case .project:
            return .project
        case .exam:
            return .exam
        case .quiz:
            return .quiz
        case .other:
            return .other
        }
    }
}
