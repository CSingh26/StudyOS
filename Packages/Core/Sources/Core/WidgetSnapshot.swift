import Foundation

public struct WidgetTask: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let dueDate: Date?
    public let courseName: String?

    public init(id: String, title: String, dueDate: Date?, courseName: String?) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.courseName = courseName
    }
}

public struct WidgetEvent: Codable, Hashable {
    public let title: String
    public let startDate: Date
    public let location: String

    public init(title: String, startDate: Date, location: String) {
        self.title = title
        self.startDate = startDate
        self.location = location
    }
}

public struct WidgetSnapshot: Codable, Hashable {
    public let todayTasks: [WidgetTask]
    public let upcomingDeadlines: [WidgetTask]
    public let nextClass: WidgetEvent?

    public init(todayTasks: [WidgetTask], upcomingDeadlines: [WidgetTask], nextClass: WidgetEvent?) {
        self.todayTasks = todayTasks
        self.upcomingDeadlines = upcomingDeadlines
        self.nextClass = nextClass
    }

    public static let empty = WidgetSnapshot(todayTasks: [], upcomingDeadlines: [], nextClass: nil)
}

public enum SharedSnapshotStore {
    private static let fileName = "widget_snapshot.json"

    public static func load() -> WidgetSnapshot {
        guard let url = containerURL() else { return .empty }
        let fileURL = url.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(WidgetSnapshot.self, from: data)) ?? .empty
    }

    public static func write(_ snapshot: WidgetSnapshot) throws {
        guard let url = containerURL() else { return }
        let fileURL = url.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL)
    }

    private static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupId)
    }
}
