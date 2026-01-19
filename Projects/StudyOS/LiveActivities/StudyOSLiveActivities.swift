import ActivityKit
import Core
import SwiftUI
import WidgetKit

struct FocusSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.attributes.taskName)
                    .font(.headline)
                Text("\(context.state.remainingMinutes) min left")
                    .font(.caption)
                if let next = context.state.nextEventMinutes {
                    Text("Next event in \(next)m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
                DynamicIslandExpandedRegion(.bottom) {
                    if let next = context.state.nextEventMinutes {
                        Text("Next event in \(next)m")
                    }
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
