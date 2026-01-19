import Canvas
import Core
import Foundation
import Storage
import SwiftData

public struct CanvasSyncReport: Sendable {
    var courses: Int = 0
    var assignments: Int = 0
    var quizzes: Int = 0
    var announcements: Int = 0
    var grades: Int = 0
    var calendarEvents: Int = 0
    var modules: Int = 0
}

@MainActor
public final class CanvasSyncEngine {
    private let context: ModelContext
    private let profile: Profile
    private let client: CanvasAPIClient
    private let logger = StudyLogger.sync

    public init?(context: ModelContext, profile: Profile) {
        guard let baseURLString = profile.canvasBaseURL,
              let baseURL = URL(string: baseURLString) else {
            return nil
        }
        self.context = context
        self.profile = profile
        self.client = CanvasAPIClient(baseURL: baseURL, profileId: profile.id)
    }

    public func syncAll() async throws -> CanvasSyncReport {
        var report = CanvasSyncReport()
        let courses = try await client.fetchCourses()
        report.courses = courses.count

        for courseDTO in courses {
            let course = upsertCourse(dto: courseDTO)

            let assignments = try await client.fetchAssignments(courseId: courseDTO.id)
            report.assignments += assignments.count
            for assignmentDTO in assignments {
                upsertAssignment(dto: assignmentDTO, course: course)
            }

            let quizzes = try await client.fetchQuizzes(courseId: courseDTO.id)
            report.quizzes += quizzes.count
            for quizDTO in quizzes {
                upsertQuiz(dto: quizDTO, course: course)
            }

            let announcements = try await client.fetchAnnouncements(courseId: courseDTO.id)
            report.announcements += announcements.count
            for announcementDTO in announcements {
                upsertAnnouncement(dto: announcementDTO, course: course)
            }

            let grades = try await client.fetchGrades(courseId: courseDTO.id)
            report.grades += grades.count
            for gradeDTO in grades {
                upsertGrade(dto: gradeDTO, course: course)
            }

            let modules = try await client.fetchModules(courseId: courseDTO.id)
            report.modules += modules.count
        }

        let calendarEvents = try await client.fetchCalendarEvents()
        report.calendarEvents = calendarEvents.count
        for eventDTO in calendarEvents {
            upsertCalendarEvent(dto: eventDTO)
        }

        profile.lastCanvasSyncAt = Date()
        profile.lastCanvasSyncError = nil
        try context.save()
        logger.info("Canvas sync completed. Courses: \(report.courses), assignments: \(report.assignments)")
        return report
    }

    private func upsertCourse(dto: CanvasCourseDTO) -> Course {
        if let existing = fetchCourse(canvasId: dto.id) {
            existing.name = dto.name
            existing.code = dto.courseCode ?? existing.code
            return existing
        }

        let course = Course(
            name: dto.name,
            code: dto.courseCode ?? "",
            colorHex: colorForCourse(dto.id),
            canvasId: dto.id,
            createdAt: Date(),
            profile: profile
        )
        context.insert(course)
        return course
    }

    private func upsertAssignment(dto: CanvasAssignmentDTO, course: Course) {
        let assignment = fetchAssignment(canvasId: dto.id) ?? Assignment(
            title: dto.name,
            dueDate: dto.dueAt,
            details: dto.description ?? "",
            estimatedMinutes: 60,
            weight: dto.pointsPossible ?? 0,
            status: .notStarted,
            canvasId: dto.id,
            submissionType: dto.submissionTypes?.joined(separator: ", ") ?? "",
            externalURL: dto.htmlURL,
            createdAt: Date(),
            updatedAt: Date(),
            course: course
        )

        assignment.title = dto.name
        assignment.dueDate = dto.dueAt
        assignment.details = dto.description ?? ""
        assignment.weight = dto.pointsPossible ?? assignment.weight
        assignment.submissionType = dto.submissionTypes?.joined(separator: ", ") ?? assignment.submissionType
        assignment.externalURL = dto.htmlURL ?? assignment.externalURL
        assignment.course = course

        if fetchAssignment(canvasId: dto.id) == nil {
            context.insert(assignment)
        }
    }

    private func upsertQuiz(dto: CanvasQuizDTO, course: Course) {
        let quiz = fetchQuiz(canvasId: dto.id) ?? Quiz(
            title: dto.title,
            dueDate: dto.dueAt,
            totalPoints: dto.pointsPossible ?? 0,
            canvasId: dto.id,
            externalURL: dto.htmlURL,
            course: course
        )

        quiz.title = dto.title
        quiz.dueDate = dto.dueAt
        quiz.totalPoints = dto.pointsPossible ?? quiz.totalPoints
        quiz.externalURL = dto.htmlURL ?? quiz.externalURL
        quiz.course = course

        if fetchQuiz(canvasId: dto.id) == nil {
            context.insert(quiz)
        }
    }

    private func upsertAnnouncement(dto: CanvasAnnouncementDTO, course: Course) {
        let message = dto.message ?? ""
        let postedAt = dto.postedAt ?? Date()
        let announcement = fetchAnnouncement(canvasId: dto.id) ?? Announcement(
            title: dto.title,
            message: message,
            postedAt: postedAt,
            canvasId: dto.id,
            externalURL: dto.htmlURL,
            course: course
        )

        announcement.title = dto.title
        announcement.message = message
        announcement.postedAt = postedAt
        announcement.externalURL = dto.htmlURL ?? announcement.externalURL
        announcement.course = course

        if fetchAnnouncement(canvasId: dto.id) == nil {
            context.insert(announcement)
        }
    }

    private func upsertGrade(dto: CanvasGradeDTO, course: Course) {
        let grade = fetchGrade(canvasId: dto.id) ?? Grade(
            score: dto.score,
            weight: 1,
            recordedAt: Date(),
            canvasId: dto.id,
            course: course
        )

        grade.score = dto.score
        grade.course = course
        if fetchGrade(canvasId: dto.id) == nil {
            context.insert(grade)
        }
    }

    private func upsertCalendarEvent(dto: CanvasCalendarEventDTO) {
        let course = courseFromContextCode(dto.contextCode)
        let event = fetchCalendarEvent(canvasId: dto.id) ?? CalendarEvent(
            title: dto.title,
            startDate: dto.startAt ?? Date(),
            endDate: dto.endAt ?? dto.startAt ?? Date(),
            location: dto.locationName ?? "",
            notes: dto.description ?? "",
            source: .canvas,
            externalId: dto.contextCode,
            canvasId: dto.id,
            course: course
        )

        event.title = dto.title
        event.startDate = dto.startAt ?? event.startDate
        event.endDate = dto.endAt ?? event.endDate
        event.location = dto.locationName ?? event.location
        event.notes = dto.description ?? event.notes
        event.course = course

        if fetchCalendarEvent(canvasId: dto.id) == nil {
            context.insert(event)
        }
    }

    private func fetchCourse(canvasId: Int) -> Course? {
        let descriptor = FetchDescriptor<Course>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func fetchAssignment(canvasId: Int) -> Assignment? {
        let descriptor = FetchDescriptor<Assignment>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func fetchQuiz(canvasId: Int) -> Quiz? {
        let descriptor = FetchDescriptor<Quiz>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func fetchAnnouncement(canvasId: Int) -> Announcement? {
        let descriptor = FetchDescriptor<Announcement>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func fetchGrade(canvasId: Int) -> Grade? {
        let descriptor = FetchDescriptor<Grade>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func fetchCalendarEvent(canvasId: Int) -> CalendarEvent? {
        let descriptor = FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.canvasId == canvasId })
        return try? context.fetch(descriptor).first
    }

    private func courseFromContextCode(_ contextCode: String?) -> Course? {
        guard let contextCode,
              contextCode.starts(with: "course_"),
              let idString = contextCode.split(separator: "_").last,
              let id = Int(idString) else {
            return nil
        }
        return fetchCourse(canvasId: id)
    }

    private func colorForCourse(_ id: Int) -> String {
        let palette = ["#E38C44", "#2F89B8", "#6A5ACD", "#2E8B57", "#B85C88"]
        return palette[id % palette.count]
    }
}
