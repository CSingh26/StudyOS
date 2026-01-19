import XCTest
import Planner

final class PriorityScorerTests: XCTestCase {
    func testDueSoonScoresHigher() {
        let weights = PriorityWeights(dueSoonFactor: 0.5, effortFactor: 0.2, weightFactor: 0.2, statusFactor: 0.05, courseImportance: 0.05)
        let soon = StudyTask(title: "Soon", dueDate: Date().addingTimeInterval(3600), estimatedMinutes: 60, type: .reading)
        let later = StudyTask(title: "Later", dueDate: Date().addingTimeInterval(10 * 24 * 60 * 60), estimatedMinutes: 60, type: .reading)

        let soonScore = PriorityScorer.score(task: soon, weights: weights)
        let laterScore = PriorityScorer.score(task: later, weights: weights)
        XCTAssertGreaterThan(soonScore, laterScore)
    }

    func testCompletedTaskScoresLower() {
        let weights = PriorityWeights(dueSoonFactor: 0.4, effortFactor: 0.2, weightFactor: 0.2, statusFactor: 0.2, courseImportance: 0.0)
        let active = StudyTask(title: "Active", dueDate: Date().addingTimeInterval(3600), estimatedMinutes: 60, type: .reading, status: .inProgress)
        let completed = StudyTask(title: "Done", dueDate: Date().addingTimeInterval(3600), estimatedMinutes: 60, type: .reading, status: .completed)

        let activeScore = PriorityScorer.score(task: active, weights: weights)
        let completedScore = PriorityScorer.score(task: completed, weights: weights)
        XCTAssertGreaterThan(activeScore, completedScore)
    }
}
