import Core
import SwiftUI
import UIComponents
import FeaturesAssignments
import FeaturesCalendar
import FeaturesGrades
import FeaturesSettings
import FeaturesToday
import FeaturesVault

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showSearch = false
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        ZStack {
            StudyColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    offlineBanner
                }
                TabView {
                    navigationTab(title: "Today", systemImage: "sun.max", view: TodayView())
                    navigationTab(title: "Assignments", systemImage: "checklist", view: AssignmentsHubView())
                    navigationTab(title: "Calendar", systemImage: "calendar", view: CalendarView())
                    navigationTab(title: "Vault", systemImage: "tray.full", view: VaultView())
                    navigationTab(title: "Grades", systemImage: "chart.bar", view: GradesView())
                    navigationTab(title: "Settings", systemImage: "gearshape", view: SettingsView())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("app-shell-root")
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .task {
            WidgetSnapshotWriter.update(context: modelContext)
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline mode: showing cached data")
                .font(StudyTypography.caption)
        }
        .foregroundColor(StudyColor.primaryText)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(StudyColor.warmAccent.opacity(0.2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline mode: showing cached data")
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
