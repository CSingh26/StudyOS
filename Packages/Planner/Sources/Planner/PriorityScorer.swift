import Foundation

public enum PriorityScorer {
    public static func score(task: StudyTask, weights: PriorityWeights, now: Date = Date()) -> Double {
        let dueScore = dueSoonScore(dueDate: task.dueDate, now: now)
        let effortScore = min(Double(task.estimatedMinutes) / 180.0, 1)
        let weightScore = min(task.weight / 100.0, 1)
        let statusScore: Double
        switch task.status {
        case .notStarted:
            statusScore = 1
        case .inProgress:
            statusScore = 0.7
        case .completed:
            statusScore = 0
        }
        let courseScore = min(max(task.courseImportance, 0), 1)

        return (dueScore * weights.dueSoonFactor)
            + (effortScore * weights.effortFactor)
            + (weightScore * weights.weightFactor)
            + (statusScore * weights.statusFactor)
            + (courseScore * weights.courseImportance)
    }

    private static func dueSoonScore(dueDate: Date?, now: Date) -> Double {
        guard let dueDate else { return 0.2 }
        let days = max(dueDate.timeIntervalSince(now) / (24 * 60 * 60), 0)
        if days <= 1 { return 1 }
        if days <= 3 { return 0.8 }
        if days <= 7 { return 0.6 }
        return 0.3
    }
}
