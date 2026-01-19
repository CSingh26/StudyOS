#if canImport(ActivityKit)
import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct FocusSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var remainingMinutes: Int
        public var nextEventMinutes: Int?

        public init(title: String, remainingMinutes: Int, nextEventMinutes: Int?) {
            self.title = title
            self.remainingMinutes = remainingMinutes
            self.nextEventMinutes = nextEventMinutes
        }
    }

    public var taskName: String

    public init(taskName: String) {
        self.taskName = taskName
    }
}
#endif
