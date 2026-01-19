import XCTest
import Planner

final class PlannerEngineTests: XCTestCase {
    func testPlansBlocksBeforeDeadline() async throws {
        let engine = SimplePlannerEngine()
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let task = StudyTask(title: "Essay", dueDate: dueDate, estimatedMinutes: 90, type: .writing)
        let constraints = PlannerConstraints(maxHoursPerDay: 2, preferredWindow: TimeWindow(startHour: 9, endHour: 18))

        let blocks = try await engine.plan(tasks: [task], constraints: constraints)
        XCTAssertFalse(blocks.isEmpty)
        XCTAssertTrue(blocks.allSatisfy { $0.end <= dueDate })
    }

    func testAvoidsWeekendsWhenDisabled() async throws {
        let engine = SimplePlannerEngine()
        let calendar = Calendar.current
        let nextSaturday = calendar.nextDate(after: Date(), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? Date()
        let task = StudyTask(title: "Problem Set", dueDate: nextSaturday, estimatedMinutes: 60, type: .problemSet)
        let constraints = PlannerConstraints(maxHoursPerDay: 1, preferredWindow: TimeWindow(startHour: 9, endHour: 17), allowWeekends: false)

        let blocks = try await engine.plan(tasks: [task], constraints: constraints)
        XCTAssertFalse(blocks.contains { calendar.isDateInWeekend($0.start) })
    }

    func testRecoveryAddsMissedMinutes() async throws {
        let engine = SimplePlannerEngine()
        let task = StudyTask(title: "Project", dueDate: Date().addingTimeInterval(5 * 24 * 60 * 60), estimatedMinutes: 60, type: .project)
        let missed = StudyBlock(taskId: task.id, start: Date(), end: Date().addingTimeInterval(30 * 60))
        let constraints = PlannerConstraints(maxHoursPerDay: 2, preferredWindow: TimeWindow(startHour: 10, endHour: 18))

        let blocks = try await engine.recover(missedBlocks: [missed], tasks: [task], constraints: constraints)
        XCTAssertGreaterThan(blocks.count, 0)
    }
}
