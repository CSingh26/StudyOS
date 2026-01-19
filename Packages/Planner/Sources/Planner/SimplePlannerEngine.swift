import Foundation

public final class SimplePlannerEngine: PlannerEngine {
    private let calendar = Calendar.current
    public init() {}

    public func plan(tasks: [StudyTask], constraints: PlannerConstraints) async throws -> [StudyBlock] {
        guard constraints.maxHoursPerDay > 0 else {
            throw PlannerError.invalidConstraints
        }

        let sorted = tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        var blocks: [StudyBlock] = []

        for task in sorted {
            let dueDate = task.dueDate ?? calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            var remaining = task.estimatedMinutes
            var dayPointer = calendar.startOfDay(for: dueDate)
            var safety = 0

            while remaining > 0 && safety < 45 {
                safety += 1
                if !constraints.allowWeekends && calendar.isDateInWeekend(dayPointer) {
                    dayPointer = calendar.date(byAdding: .day, value: -1, to: dayPointer) ?? dayPointer
                    continue
                }

                let available = availableIntervals(on: dayPointer, constraints: constraints)
                var scheduledToday = minutesScheduled(on: dayPointer, for: task.id, blocks: blocks)
                let maxMinutes = constraints.maxHoursPerDay * 60

                for slot in available {
                    if remaining <= 0 || scheduledToday >= maxMinutes { break }
                    let slotMinutes = min(Int(slot.duration / 60), maxMinutes - scheduledToday)
                    let minutes = min(slotMinutes, remaining)
                    let end = slot.start.addingTimeInterval(TimeInterval(minutes * 60))
                    blocks.append(StudyBlock(taskId: task.id, start: slot.start, end: end))
                    remaining -= minutes
                    scheduledToday += minutes
                }

                dayPointer = calendar.date(byAdding: .day, value: -1, to: dayPointer) ?? dayPointer
            }
        }

        return blocks
    }

    public func recover(missedBlocks: [StudyBlock], tasks: [StudyTask], constraints: PlannerConstraints) async throws -> [StudyBlock] {
        var adjusted = tasks
        for missed in missedBlocks {
            if let index = adjusted.firstIndex(where: { $0.id == missed.taskId }) {
                let additional = Int(missed.end.timeIntervalSince(missed.start) / 60)
                adjusted[index].estimatedMinutes += additional
            }
        }
        return try await plan(tasks: adjusted, constraints: constraints)
    }

    private func minutesScheduled(on day: Date, for taskId: UUID, blocks: [StudyBlock]) -> Int {
        blocks.filter { calendar.isDate($0.start, inSameDayAs: day) && $0.taskId == taskId }
            .reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start) / 60) }
    }

    private func availableIntervals(on day: Date, constraints: PlannerConstraints) -> [DateInterval] {
        let startHour = constraints.preferredWindow.startHour
        let endHour = constraints.preferredWindow.endHour
        guard let start = date(on: day, hour: startHour),
              let end = date(on: day, hour: endHour) else {
            return []
        }
        var intervals = [DateInterval(start: start, end: end)]

        for window in constraints.noStudyWindows {
            if let blockStart = date(on: day, hour: window.startHour),
               let blockEnd = date(on: day, hour: window.endHour) {
                intervals = subtract(intervals: intervals, blocked: DateInterval(start: blockStart, end: blockEnd))
            }
        }

        for busy in constraints.busyIntervals {
            if calendar.isDate(busy.start, inSameDayAs: day) {
                intervals = subtract(intervals: intervals, blocked: busy)
            }
        }

        return intervals
    }

    private func date(on day: Date, hour: Int) -> Date? {
        let startOfDay = calendar.startOfDay(for: day)
        if hour == 24 {
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)
        }
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)
    }

    private func subtract(intervals: [DateInterval], blocked: DateInterval) -> [DateInterval] {
        var result: [DateInterval] = []
        for interval in intervals {
            if !interval.intersects(blocked) {
                result.append(interval)
                continue
            }
            if interval.start < blocked.start {
                result.append(DateInterval(start: interval.start, end: blocked.start))
            }
            if interval.end > blocked.end {
                result.append(DateInterval(start: blocked.end, end: interval.end))
            }
        }
        return result.filter { $0.duration > 0 }
    }
}
