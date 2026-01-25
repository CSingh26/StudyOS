import Core
import SwiftUI
import UIComponents
import WidgetKit

struct StudyOSWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StudyOSProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyOSWidgetEntry {
        StudyOSWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyOSWidgetEntry) -> Void) {
        completion(StudyOSWidgetEntry(date: Date(), snapshot: SharedSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyOSWidgetEntry>) -> Void) {
        let entry = StudyOSWidgetEntry(date: Date(), snapshot: SharedSnapshotStore.load())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct StudyOSTodayTasksWidgetView: View {
    let entry: StudyOSWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    private var theme: StudyTheme {
        widgetTheme(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            ForEach(entry.snapshot.todayTasks.prefix(3)) { task in
                Text(task.title)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
            }
            if entry.snapshot.todayTasks.isEmpty {
                Text("No tasks")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .containerBackground(theme.background, for: .widget)
    }
}

struct StudyOSNextClassWidgetView: View {
    let entry: StudyOSWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    private var theme: StudyTheme {
        widgetTheme(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next Class")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            if let next = entry.snapshot.nextClass {
                Text(next.title)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
                Text(next.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            } else {
                Text("No upcoming class")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .containerBackground(theme.background, for: .widget)
    }
}

struct StudyOSDeadlinesWidgetView: View {
    let entry: StudyOSWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    private var theme: StudyTheme {
        widgetTheme(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Deadlines")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            ForEach(entry.snapshot.upcomingDeadlines.prefix(3)) { task in
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.caption)
                        .foregroundColor(theme.textPrimary)
                    if let due = task.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            if entry.snapshot.upcomingDeadlines.isEmpty {
                Text("No deadlines")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .containerBackground(theme.background, for: .widget)
    }
}

struct StudyOSTodayWidget: Widget {
    let kind: String = "StudyOSTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyOSProvider()) { entry in
            StudyOSTodayTasksWidgetView(entry: entry)
        }
        .configurationDisplayName("StudyOS Today")
        .description("Top tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StudyOSNextClassWidget: Widget {
    let kind: String = "StudyOSNextClassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyOSProvider()) { entry in
            StudyOSNextClassWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Class")
        .description("Your next class event.")
        .supportedFamilies([.systemSmall])
    }
}

struct StudyOSDeadlinesWidget: Widget {
    let kind: String = "StudyOSDeadlinesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyOSProvider()) { entry in
            StudyOSDeadlinesWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Deadlines")
        .description("Upcoming due dates.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct StudyOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyOSTodayWidget()
        StudyOSNextClassWidget()
        StudyOSDeadlinesWidget()
    }
}

private func widgetTheme(for scheme: ColorScheme) -> StudyTheme {
    let defaults = UserDefaults(suiteName: AppConstants.appGroupId) ?? .standard
    let mode = ThemeMode.load(from: defaults)
    return StudyTheme.resolved(for: mode, systemScheme: scheme)
}
