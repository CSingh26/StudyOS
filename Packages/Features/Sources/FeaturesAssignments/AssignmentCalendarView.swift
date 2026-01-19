import Storage
import SwiftUI
import UIComponents

struct AssignmentCalendarView: View {
    let assignments: [Assignment]
    let calendarEvents: [CalendarEvent]
    let studyBlocks: [StudyBlock]

    @State private var monthOffset: Int = 0
    @State private var selectedDate: Date? = Date()

    private var calendar: Calendar {
        Calendar.current
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                StudyText(monthTitle, style: .headline)
                Spacer()
                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(StudyTypography.caption)
                        .foregroundColor(StudyColor.secondaryText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(date)
                }
            }

            if let selected = selectedDate {
                dayDetails(for: selected)
            }
        }
        .padding(8)
    }

    private var monthTitle: String {
        let date = monthDate
        return date.formatted(.dateTime.month(.wide).year())
    }

    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let firstWeekday = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)?.start else {
            return []
        }
        var dates: [Date] = []
        for dayOffset in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstWeekday) {
                dates.append(date)
            }
        }
        return dates
    }

    private var weekdays: [String] {
        let symbols = calendar.shortWeekdaySymbols
        return symbols
    }

    private func dayCell(_ date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: monthDate, toGranularity: .month)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let markers = markersForDate(date)

        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(StudyTypography.caption)
                .foregroundColor(isCurrentMonth ? StudyColor.primaryText : StudyColor.secondaryText)
                .frame(width: 28, height: 28)
                .background(isSelected ? StudyColor.coolAccent.opacity(0.2) : Color.clear)
                .clipShape(Circle())

            HStack(spacing: 3) {
                ForEach(markers, id: \.self) { marker in
                    Circle()
                        .fill(marker.color)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDate = date
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: date, markers: markers))
    }

    private func markersForDate(_ date: Date) -> [CalendarMarker] {
        var markers: [CalendarMarker] = []
        let dayAssignments = assignments.filter { assignment in
            guard let dueDate = assignment.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
        if !dayAssignments.isEmpty {
            markers.append(.assignment)
        }
        let dayEvents = calendarEvents.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        if !dayEvents.isEmpty {
            markers.append(.event)
        }
        let dayBlocks = studyBlocks.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        if !dayBlocks.isEmpty {
            markers.append(.studyBlock)
        }
        return markers
    }

    private func dayDetails(for date: Date) -> some View {
        let dayAssignments = assignments.filter { assignment in
            guard let dueDate = assignment.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
        let dayEvents = calendarEvents.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        let dayBlocks = studyBlocks.filter { calendar.isDate($0.startDate, inSameDayAs: date) }

        return StudyCard {
            VStack(alignment: .leading, spacing: 8) {
                StudyText(date.formatted(date: .abbreviated, time: .omitted), style: .headline)
                if dayAssignments.isEmpty && dayEvents.isEmpty && dayBlocks.isEmpty {
                    StudyText("No items for this day.", style: .caption, color: StudyColor.secondaryText)
                }
                ForEach(dayAssignments) { assignment in
                    StudyText("Due: \(assignment.title)", style: .body)
                }
                ForEach(dayEvents) { event in
                    StudyText("Event: \(event.title)", style: .body)
                }
                ForEach(dayBlocks) { block in
                    StudyText("Study block", style: .body)
                }
            }
        }
    }

    private func accessibilityLabel(for date: Date, markers: [CalendarMarker]) -> String {
        let base = date.formatted(date: .long, time: .omitted)
        guard !markers.isEmpty else { return base }
        let markerText = markers.map { $0.label }.joined(separator: ", ")
        return "\(base), \(markerText)"
    }
}

private enum CalendarMarker: String, CaseIterable {
    case assignment
    case event
    case studyBlock

    var color: Color {
        switch self {
        case .assignment: return StudyColor.coolAccent
        case .event: return StudyColor.warmAccent
        case .studyBlock: return StudyColor.secondaryText
        }
    }

    var label: String {
        switch self {
        case .assignment: return "Assignments due"
        case .event: return "Events"
        case .studyBlock: return "Study blocks"
        }
    }
}
