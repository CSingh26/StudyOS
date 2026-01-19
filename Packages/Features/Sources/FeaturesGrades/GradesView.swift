import Storage
import SwiftData
import SwiftUI
import UIComponents

public struct GradesView: View {
    @Query(sort: \Course.name) private var courses: [Course]

    public init() {}

    public var body: some View {
        List {
            ForEach(courses) { course in
                NavigationLink {
                    CourseGradesView(course: course)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.name)
                            .font(StudyTypography.headline)
                        Text("Grades: \(course.grades.count)")
                            .font(StudyTypography.caption)
                            .foregroundColor(StudyColor.secondaryText)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
