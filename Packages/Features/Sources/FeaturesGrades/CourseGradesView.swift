import Foundation
import Storage
import SwiftData
import SwiftUI
import UIComponents

struct CourseGradesView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: Course
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]

    @State private var manualTitle: String = ""
    @State private var manualScore: Double = 90
    @State private var manualWeight: Double = 10
    @State private var syllabusText: String = ""
    @State private var suggestions: [SyllabusSuggestion] = []

    var body: some View {
        List {
            Section("Current Grade") {
                Text(currentGradeText)
                    .font(StudyTypography.headline)
                if let required = requiredScoreForTarget {
                    Text("Need \(formattedPercent(required, digits: 1))% on remaining work to reach \(formattedPercent(course.targetGrade, digits: 0))%")
                        .font(StudyTypography.caption)
                        .foregroundColor(StudyColor.secondaryText)
                }
                Slider(value: $course.targetGrade, in: 60...100, step: 1)
                Toggle("Manual grades mode", isOn: $course.manualGradesEnabled)
            }

            Section("Manual Grades") {
                ForEach(manualGrades) { grade in
                    HStack {
                        Text(grade.title)
                        Spacer()
                        Text("\(formattedPercent(grade.score, digits: 1))%")
                            .foregroundColor(StudyColor.secondaryText)
                        Text("(\(formattedPercent(grade.weight, digits: 0))%)")
                            .foregroundColor(StudyColor.secondaryText)
                    }
                }
                HStack {
                    TextField("Title", text: $manualTitle)
                    TextField("Score", value: $manualScore, formatter: Self.oneDecimalFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Weight", value: $manualWeight, formatter: Self.wholeNumberFormatter)
                        .keyboardType(.decimalPad)
                }
                Button("Add Grade") {
                    addManualGrade()
                }
            }

            Section("What matters next") {
                ForEach(upcomingAssignments.prefix(3)) { assignment in
                    HStack {
                        Text(assignment.title)
                            .font(StudyTypography.body)
                        Spacer()
                        Text("Weight \(formattedPercent(assignment.weight, digits: 0))")
                            .font(StudyTypography.caption)
                            .foregroundColor(StudyColor.secondaryText)
                    }
                }
            }

            Section("Syllabus extraction") {
                TextEditor(text: $syllabusText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(StudyColor.divider, lineWidth: 1)
                    )
                Button("Extract weights") {
                    suggestions = extractSuggestions(from: syllabusText)
                }
                if !suggestions.isEmpty {
                    ForEach(suggestions) { suggestion in
                        HStack {
                            Text("\(suggestion.title) \(formattedPercent(suggestion.weight, digits: 0))%")
                            Spacer()
                            Button("Add") {
                                addSuggestion(suggestion)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .onChange(of: course.manualGradesEnabled) { _ in
            try? modelContext.save()
        }
        .onChange(of: course.targetGrade) { _ in
            try? modelContext.save()
        }
    }

    private var manualGrades: [Grade] {
        course.grades.filter { $0.isManual }
    }

    private var currentGradeText: String {
        if course.manualGradesEnabled || course.grades.filter({ !$0.isManual }).isEmpty {
            let score = weightedAverage(manualGrades)
            return "Manual grade: \(formattedPercent(score, digits: 1))%"
        }
        let canvasScores = course.grades.filter { !$0.isManual }.map { $0.score }
        let avg = canvasScores.isEmpty ? 0 : canvasScores.reduce(0, +) / Double(canvasScores.count)
        return "Canvas grade: \(formattedPercent(avg, digits: 1))%"
    }

    private var requiredScoreForTarget: Double? {
        guard course.manualGradesEnabled else { return nil }
        let completedWeight = manualGrades.reduce(0) { $0 + $1.weight }
        let remainingWeight = max(0, 100 - completedWeight)
        guard remainingWeight > 0 else { return nil }
        let currentWeighted = manualGrades.reduce(0) { $0 + ($1.score * $1.weight / 100) }
        let targetWeighted = course.targetGrade
        return max(0, (targetWeighted - currentWeighted) / remainingWeight * 100)
    }

    private var upcomingAssignments: [Assignment] {
        assignments.filter { $0.course?.id == course.id && $0.status != .submitted }
            .sorted { $0.weight > $1.weight }
    }

    private func weightedAverage(_ grades: [Grade]) -> Double {
        let totalWeight = grades.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let weighted = grades.reduce(0) { $0 + ($1.score * $1.weight / 100) }
        return weighted / totalWeight * 100
    }

    private func addManualGrade() {
        let title = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let grade = Grade(
            title: title,
            score: manualScore,
            weight: manualWeight,
            recordedAt: Date(),
            canvasId: nil,
            isManual: true,
            course: course
        )
        modelContext.insert(grade)
        manualTitle = ""
        manualScore = 90
        manualWeight = 10
        try? modelContext.save()
    }

    private func extractSuggestions(from text: String) -> [SyllabusSuggestion] {
        let pattern = "([A-Za-z][A-Za-z -]+)\\s*(\\d{1,2})%"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match in
            guard let titleRange = Range(match.range(at: 1), in: text),
                  let weightRange = Range(match.range(at: 2), in: text) else { return nil }
            let title = text[titleRange].trimmingCharacters(in: .whitespacesAndNewlines)
            let weight = Double(text[weightRange]) ?? 0
            return SyllabusSuggestion(title: title, weight: weight)
        }
    }

    private func addSuggestion(_ suggestion: SyllabusSuggestion) {
        let grade = Grade(
            title: suggestion.title,
            score: 0,
            weight: suggestion.weight,
            recordedAt: Date(),
            canvasId: nil,
            isManual: true,
            course: course
        )
        modelContext.insert(grade)
        try? modelContext.save()
    }

    private func formattedPercent(_ value: Double, digits: Int) -> String {
        let formatter = digits == 0 ? Self.wholeNumberFormatter : Self.oneDecimalFormatter
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(digits)f", value)
    }
}

extension CourseGradesView {
    private static let oneDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    private static let wholeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

struct SyllabusSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let weight: Double
}
