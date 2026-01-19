import SwiftUI
import UIComponents
import FeaturesAssignments
import FeaturesCalendar
import FeaturesGrades
import FeaturesSettings
import FeaturesToday
import FeaturesVault

struct AppShellView: View {
    @State private var showSearch = false

    var body: some View {
        ZStack {
            StudyColor.background.ignoresSafeArea()
            TabView {
                navigationTab(title: "Today", systemImage: "sun.max", view: TodayPlaceholderView())
                navigationTab(title: "Assignments", systemImage: "checklist", view: AssignmentsPlaceholderView())
                navigationTab(title: "Calendar", systemImage: "calendar", view: CalendarView())
                navigationTab(title: "Vault", systemImage: "tray.full", view: VaultPlaceholderView())
                navigationTab(title: "Grades", systemImage: "chart.bar", view: GradesPlaceholderView())
                navigationTab(title: "Settings", systemImage: "gearshape", view: SettingsView())
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }

    private func navigationTab<V: View>(title: String, systemImage: String, view: V) -> some View {
        NavigationStack {
            view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(StudyColor.background)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .accessibilityLabel("Search")
                        .accessibilityHint("Search across courses, tasks, and notes")
                    }
                }
        }
        .tabItem {
            Label(title, systemImage: systemImage)
        }
        .accessibilityLabel(title)
    }
}
