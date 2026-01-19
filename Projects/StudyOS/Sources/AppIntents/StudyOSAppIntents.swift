import AppIntents
import Core
import Foundation

struct WhatsDueTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "What's due tomorrow?"
    static var description = IntentDescription("Get a summary of items due tomorrow.")

    func perform() async throws -> some IntentResult {
        let snapshot = SharedSnapshotStore.load()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tasks = snapshot.upcomingDeadlines.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: tomorrow)
        }
        if tasks.isEmpty {
            return .result(dialog: "Nothing is due tomorrow.")
        }
        let titles = tasks.map { $0.title }.joined(separator: ", ")
        return .result(dialog: "Due tomorrow: \(titles).")
    }
}

struct StartFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start focus session"
    static var description = IntentDescription("Open StudyOS to start a focus session.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result(dialog: "Opening StudyOS.")
    }
}

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add task"
    static var description = IntentDescription("Open StudyOS to add a new task.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Task Title")
    var titleText: String?

    func perform() async throws -> some IntentResult {
        if let titleText {
            return .result(dialog: "Opening StudyOS to add \(titleText).")
        }
        return .result(dialog: "Opening StudyOS.")
    }
}

struct OpenNextClassIntent: AppIntent {
    static var title: LocalizedStringResource = "Open next class"
    static var description = IntentDescription("Open the next class in StudyOS.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result(dialog: "Opening StudyOS.")
    }
}

struct StudyOSShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: WhatsDueTomorrowIntent(), phrases: ["What's due tomorrow in \(.applicationName)"])
        AppShortcut(intent: StartFocusSessionIntent(), phrases: ["Start focus session in \(.applicationName)"])
        AppShortcut(intent: AddTaskIntent(), phrases: ["Add a task in \(.applicationName)"])
        AppShortcut(intent: OpenNextClassIntent(), phrases: ["Open next class in \(.applicationName)"])
    }
}
