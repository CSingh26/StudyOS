import Foundation

public struct TaskTemplateStep: Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var estimatedMinutes: Int

    public init(id: UUID = UUID(), title: String, estimatedMinutes: Int) {
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
    }
}

public struct TaskTemplate: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: TaskType
    public var steps: [TaskTemplateStep]

    public init(id: UUID = UUID(), name: String, kind: TaskType, steps: [TaskTemplateStep]) {
        self.id = id
        self.name = name
        self.kind = kind
        self.steps = steps
    }
}

public enum TaskTemplateEngine {
    public static func defaultTemplates() -> [TaskTemplate] {
        [
            TaskTemplate(name: "Reading", kind: .reading, steps: [
                TaskTemplateStep(title: "Skim headings and summaries", estimatedMinutes: 20),
                TaskTemplateStep(title: "Deep read key sections", estimatedMinutes: 40),
                TaskTemplateStep(title: "Write notes and questions", estimatedMinutes: 20)
            ]),
            TaskTemplate(name: "Writing", kind: .writing, steps: [
                TaskTemplateStep(title: "Outline key points", estimatedMinutes: 25),
                TaskTemplateStep(title: "Draft main sections", estimatedMinutes: 60),
                TaskTemplateStep(title: "Edit and format", estimatedMinutes: 25)
            ]),
            TaskTemplate(name: "Coding", kind: .coding, steps: [
                TaskTemplateStep(title: "Clarify requirements", estimatedMinutes: 20),
                TaskTemplateStep(title: "Implement core solution", estimatedMinutes: 60),
                TaskTemplateStep(title: "Test and polish", estimatedMinutes: 30)
            ]),
            TaskTemplate(name: "Problem Set", kind: .problemSet, steps: [
                TaskTemplateStep(title: "Review formulas", estimatedMinutes: 20),
                TaskTemplateStep(title: "Solve problems", estimatedMinutes: 60),
                TaskTemplateStep(title: "Check work", estimatedMinutes: 20)
            ]),
            TaskTemplate(name: "Project", kind: .project, steps: [
                TaskTemplateStep(title: "Define milestones", estimatedMinutes: 30),
                TaskTemplateStep(title: "Build deliverable", estimatedMinutes: 90),
                TaskTemplateStep(title: "Finalize and submit", estimatedMinutes: 30)
            ])
        ]
    }

    public static func steps(for kind: TaskType) -> [TaskTemplateStep] {
        defaultTemplates().first { $0.kind == kind }?.steps ?? [
            TaskTemplateStep(title: "Plan task", estimatedMinutes: 15),
            TaskTemplateStep(title: "Execute", estimatedMinutes: 45),
            TaskTemplateStep(title: "Review", estimatedMinutes: 15)
        ]
    }
}
