import SwiftUI
import UIComponents

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Search courses, tasks, and notes", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Search")
                    .padding(.horizontal)

                if query.isEmpty {
                    EmptyStateView(
                        title: "Start searching",
                        message: "Look up assignments, notes, or files across StudyOS."
                    )
                } else {
                    EmptyStateView(
                        title: "No results",
                        message: "We will surface matches as data loads."
                    )
                }

                Spacer()
            }
            .padding(.top, 24)
            .background(StudyColor.background)
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
