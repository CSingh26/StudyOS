import Core
import Foundation

public enum PlannerSettingsStore {
    public static func constraints(from defaults: UserDefaults = .standard) -> PlannerConstraints {
        let maxHours = defaults.integer(forKey: AppConstants.plannerMaxHoursKey)
        let startHour = defaults.integer(forKey: AppConstants.plannerStartHourKey)
        let endHour = defaults.integer(forKey: AppConstants.plannerEndHourKey)
        let allowWeekends = defaults.object(forKey: AppConstants.plannerAllowWeekendsKey) as? Bool ?? true

        let resolvedMaxHours = maxHours == 0 ? 4 : maxHours
        let resolvedStart = startHour == 0 ? 9 : startHour
        let resolvedEnd = endHour == 0 ? 20 : endHour

        return PlannerConstraints(
            maxHoursPerDay: resolvedMaxHours,
            preferredWindow: TimeWindow(startHour: resolvedStart, endHour: resolvedEnd),
            noStudyWindows: [],
            allowWeekends: allowWeekends,
            busyIntervals: []
        )
    }

    public static func weights(from defaults: UserDefaults = .standard) -> PriorityWeights {
        let dueSoon = defaults.object(forKey: AppConstants.priorityDueSoonKey) as? Double ?? 0.35
        let effort = defaults.object(forKey: AppConstants.priorityEffortKey) as? Double ?? 0.2
        let weight = defaults.object(forKey: AppConstants.priorityWeightKey) as? Double ?? 0.25
        let status = defaults.object(forKey: AppConstants.priorityStatusKey) as? Double ?? 0.1
        let course = defaults.object(forKey: AppConstants.priorityCourseKey) as? Double ?? 0.1

        return PriorityWeights(
            dueSoonFactor: dueSoon,
            effortFactor: effort,
            weightFactor: weight,
            statusFactor: status,
            courseImportance: course
        )
    }
}
