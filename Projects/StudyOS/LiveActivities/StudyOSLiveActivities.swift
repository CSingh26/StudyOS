import ActivityKit
import Core
import SwiftUI
import UIComponents
import WidgetKit

private struct FocusSessionLiveActivityView: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    @Environment(\.colorScheme) private var colorScheme

    private var theme: StudyTheme {
        liveActivityTheme(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.attributes.taskName)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            Text("\(context.state.remainingMinutes) min left")
                .font(.caption)
                .foregroundColor(theme.textPrimary)
            if let next = context.state.nextEventMinutes {
                Text("Next event in \(next)m")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .activityBackgroundTint(theme.background)
        .activitySystemActionForegroundColor(theme.textPrimary)
    }
}

struct FocusSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            FocusSessionLiveActivityView(context: context)
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

private func liveActivityTheme(for scheme: ColorScheme) -> StudyTheme {
    let defaults = UserDefaults(suiteName: AppConstants.appGroupId) ?? .standard
    let mode = ThemeMode.load(from: defaults)
    return StudyTheme.resolved(for: mode, systemScheme: scheme)
}
