import Foundation
import SwiftUI

public struct WorkloadHeatmapDay: Identifiable {
    public let id = UUID()
    public let date: Date
    public let minutes: Int
    public let hasDeadline: Bool
}

public struct WorkloadHeatmapView: View {
    private let days: [WorkloadHeatmapDay]
    private let calendar = Calendar.current

    public init(blocks: [StudyBlock], deadlines: [Date], weekOf: Date = Date()) {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekOf)?.start ?? weekOf
        var result: [WorkloadHeatmapDay] = []
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? startOfWeek
            let minutes = blocks
                .filter { calendar.isDate($0.start, inSameDayAs: day) }
                .reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start) / 60) }
            let hasDeadline = deadlines.contains { calendar.isDate($0, inSameDayAs: day) }
            result.append(WorkloadHeatmapDay(date: day, minutes: minutes, hasDeadline: hasDeadline))
        }
        self.days = result
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    Text(dayLabel(for: day.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color(for: day.minutes))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(day.hasDeadline ? Color.orange : Color.clear, lineWidth: 2)
                        )
                        .accessibilityLabel(accessibilityLabel(for: day))
                }
            }
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return formatter.string(from: date)
    }

    private func color(for minutes: Int) -> Color {
        switch minutes {
        case 0:
            return Color.gray.opacity(0.15)
        case 1...30:
            return Color.green.opacity(0.35)
        case 31...90:
            return Color.green.opacity(0.55)
        case 91...180:
            return Color.green.opacity(0.75)
        default:
            return Color.green
        }
    }

    private func accessibilityLabel(for day: WorkloadHeatmapDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        let deadlineText = day.hasDeadline ? ", deadline" : ""
        return "\(date), \(day.minutes) minutes planned\(deadlineText)"
    }
}
