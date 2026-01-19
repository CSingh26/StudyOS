import SwiftUI
import WidgetKit

struct StudyOSWidgetEntry: TimelineEntry {
    let date: Date
}

struct StudyOSProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyOSWidgetEntry {
        StudyOSWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyOSWidgetEntry) -> Void) {
        completion(StudyOSWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyOSWidgetEntry>) -> Void) {
        let entry = StudyOSWidgetEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct StudyOSTodayWidgetView: View {
    var entry: StudyOSWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("StudyOS")
                .font(.headline)
            Text("Open the app to see today’s plan.")
                .font(.caption)
        }
        .padding()
    }
}

struct StudyOSTodayWidget: Widget {
    let kind: String = "StudyOSTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyOSProvider()) { entry in
            StudyOSTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("StudyOS Today")
        .description("Quick glance at your study plan.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct StudyOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyOSTodayWidget()
    }
}
