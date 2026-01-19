import ActivityKit
import SwiftUI
import WidgetKit

struct FocusSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var remainingMinutes: Int
    }

    var taskName: String
}

struct FocusSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.attributes.taskName)
                    .font(.headline)
                Text("\(context.state.remainingMinutes) min left")
                    .font(.caption)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.taskName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.remainingMinutes)m")
                }
            } compactLeading: {
                Text("\(context.state.remainingMinutes)m")
            } compactTrailing: {
                Image(systemName: "timer")
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

@main
struct StudyOSLiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        FocusSessionLiveActivityWidget()
    }
}
