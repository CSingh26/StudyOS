import Canvas
import Core
import Features
import FeaturesCollaboration
import Planner
import SwiftData
import SwiftUI
import Storage
import UIComponents
import UIKit

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var newProfileName: String = ""
    @StateObject private var canvasAuth = CanvasAuthViewModel()
    @State private var canvasBaseURL: String = ""
    @State private var canvasClientId: String = ""
    @State private var canvasRedirectURI: String = ""
    @State private var canvasScopes: String = "url:GET|/api/v1/*"
    @State private var canvasLimitedMode: Bool = false
    @AppStorage(AppConstants.priorityDueSoonKey) private var dueSoonWeight: Double = 0.35
    @AppStorage(AppConstants.priorityEffortKey) private var effortWeight: Double = 0.2
    @AppStorage(AppConstants.priorityWeightKey) private var weightWeight: Double = 0.25
    @AppStorage(AppConstants.priorityStatusKey) private var statusWeight: Double = 0.1
    @AppStorage(AppConstants.priorityCourseKey) private var courseWeight: Double = 0.1
    @AppStorage(AppConstants.plannerMaxHoursKey) private var maxHoursPerDay: Int = 4
    @AppStorage(AppConstants.plannerStartHourKey) private var preferredStartHour: Int = 9
    @AppStorage(AppConstants.plannerEndHourKey) private var preferredEndHour: Int = 20
    @AppStorage(AppConstants.plannerAllowWeekendsKey) private var allowWeekends: Bool = true
    @AppStorage(AppConstants.plannerNoStudyEnabledKey) private var noStudyEnabled: Bool = false
    @AppStorage(AppConstants.plannerNoStudyStartKey) private var noStudyStart: Int = 22
    @AppStorage(AppConstants.plannerNoStudyEndKey) private var noStudyEnd: Int = 7
    @AppStorage(AppConstants.plannerExportCalendarKey) private var exportCalendarEnabled: Bool = false
    @AppStorage(AppConstants.notificationsAssignmentsEnabledKey) private var assignmentsEnabled: Bool = true
    @AppStorage(AppConstants.notificationsStudyBlocksEnabledKey) private var studyBlocksEnabled: Bool = true
    @AppStorage(AppConstants.notificationsClassEnabledKey) private var classEnabled: Bool = true
    @AppStorage(AppConstants.notificationsLeaveNowEnabledKey) private var leaveNowEnabled: Bool = false
    @AppStorage(AppConstants.appLockEnabledKey) private var appLockEnabled: Bool = false
    @AppStorage(ThemeMode.storageKey) private var themeModeRaw: String = ThemeMode.system.rawValue

    @StateObject private var leaveNowService = LeaveNowAlertService()
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportErrorMessage = ""
    @State private var showExportError = false
    @State private var showLogoutConfirmation = false

    public init() {}

    public var body: some View {
        List {
            canvasSection
            profilesSection
            appearanceSection
            syncSection
            securitySection
            planningSection
            collaborationSection
            routineBuilderSection
            notificationsSection
            priorityWeightsSection
            aiSection
            dataExportSection
            addProfileSection
            accountSection
        }
        .listStyle(.insetGrouped)
        .onAppear {
            loadCanvasSettings()
            ThemeMode.store(rawValue: themeModeRaw, in: themeDefaults)
        }
        .onChange(of: profileSession.activeProfileId) { _ in
            loadCanvasSettings()
        }
        .onChange(of: themeModeRaw) { _ in
            ThemeMode.store(rawValue: themeModeRaw, in: themeDefaults)
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ActivityView(activityItems: [exportURL])
            }
        }
        .alert("Export failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
        .alert("Log out of StudyOS?", isPresented: $showLogoutConfirmation) {
            Button("Log out", role: .destructive) {
                logoutCurrentProfile()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You’ll return to onboarding. Local data stays on this device.")
        }
    }

    @ViewBuilder
    private var canvasSection: some View {
        Section("Canvas") {
            TextField("Base URL", text: $canvasBaseURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            TextField("Client ID", text: $canvasClientId)
                .textInputAutocapitalization(.never)
            TextField("Redirect URI", text: $canvasRedirectURI)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            TextField("Scopes", text: $canvasScopes)
                .textInputAutocapitalization(.never)
            Toggle("Limited Mode", isOn: $canvasLimitedMode)

            Button("Save Canvas Settings") {
                saveCanvasSettings()
            }
            .buttonStyle(.bordered)

            Button(canvasAuth.isConnecting ? "Connecting..." : "Connect Canvas") {
                connectCanvas()
            }
            .buttonStyle(.borderedProminent)
            .disabled(canvasLimitedMode || canvasBaseURL.isEmpty || canvasClientId.isEmpty || canvasRedirectURI.isEmpty)

            if let status = canvasAuth.statusMessage {
                Text(status)
                    .font(StudyTypography.caption)
                    .foregroundColor(StudyColor.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var profilesSection: some View {
        Section("Profiles") {
            ForEach(profiles) { profile in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(StudyTypography.headline)
                        if profile.isDemo {
                            Text("Demo mode")
                                .font(StudyTypography.caption)
                                .foregroundColor(StudyColor.secondaryText)
                        }
                    }
                    Spacer()
                    if profileSession.activeProfileId == profile.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(StudyColor.coolAccent)
                            .accessibilityLabel("Active profile")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setActiveProfile(profile)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeModeRaw) {
                ForEach(ThemeMode.allCases) { mode in
                    ThemeOptionRow(mode: mode)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.inline)
        }
    }

    @ViewBuilder
    private var syncSection: some View {
        Section("Sync") {
            NavigationLink("Sync Health") {
                SyncHealthView()
            }
        }
    }

    @ViewBuilder
    private var securitySection: some View {
        Section("Security") {
            Toggle("App Lock (Face ID / Touch ID)", isOn: $appLockEnabled)
            Text("Require biometric unlock when reopening StudyOS.")
                .font(StudyTypography.caption)
                .foregroundColor(StudyColor.secondaryText)
        }
    }

    @ViewBuilder
    private var planningSection: some View {
        Section("Planning") {
            NavigationLink("Templates") {
                TemplateLibraryView()
            }
        }
    }

    @ViewBuilder
    private var collaborationSection: some View {
        Section("Collaboration") {
            NavigationLink("Study Groups") {
                CollaborationView()
            }
        }
    }

    @ViewBuilder
    private var routineBuilderSection: some View {
        Section("Routine Builder") {
            Stepper("Max hours per day: \(maxHoursPerDay)", value: $maxHoursPerDay, in: 1...8)
            Toggle("Allow weekends", isOn: $allowWeekends)
            Picker("Preferred start", selection: $preferredStartHour) {
                ForEach(5..<23, id: \.self) { hour in
                    Text("\(hour):00").tag(hour)
                }
            }
            Picker("Preferred end", selection: $preferredEndHour) {
                ForEach(6..<24, id: \.self) { hour in
                    Text("\(hour):00").tag(hour)
                }
            }
            Toggle("No-study window", isOn: $noStudyEnabled)
            if noStudyEnabled {
                Picker("No-study start", selection: $noStudyStart) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                Picker("No-study end", selection: $noStudyEnd) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                Text("If the end time is earlier than the start time, StudyOS treats it as an overnight quiet window.")
                    .font(StudyTypography.caption)
                    .foregroundColor(StudyColor.secondaryText)
            }
            Toggle("Export study blocks to StudyOS Calendar", isOn: $exportCalendarEnabled)
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Assignment reminders", isOn: $assignmentsEnabled)
            Toggle("Study block reminders", isOn: $studyBlocksEnabled)
            Toggle("Class reminders", isOn: $classEnabled)
            Toggle("Leave-now alerts", isOn: $leaveNowEnabled)
                .onChange(of: leaveNowEnabled) { value in
                    if value {
                        leaveNowService.requestAuthorizationIfNeeded()
                    }
                }

            Button("Schedule reminders now") {
                Task {
                    let preferences = NotificationPreferences(
                        assignmentReminders: assignmentsEnabled,
                        studyBlockReminders: studyBlocksEnabled,
                        classReminders: classEnabled
                    )
                    let weights = PlannerSettingsStore.weights(from: UserDefaults.standard)
                    await NotificationScheduler.scheduleAll(context: modelContext, preferences: preferences, weights: weights)

                    if leaveNowEnabled {
                        let events = (try? modelContext.fetch(FetchDescriptor<CalendarEvent>())) ?? []
                        await leaveNowService.scheduleLeaveNowAlerts(events: events)
                    }
                }
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var priorityWeightsSection: some View {
        Section("Priority Weights") {
            weightSlider(title: "Due soon", value: $dueSoonWeight)
            weightSlider(title: "Effort", value: $effortWeight)
            weightSlider(title: "Weight", value: $weightWeight)
            weightSlider(title: "Status", value: $statusWeight)
            weightSlider(title: "Course importance", value: $courseWeight)
        }
    }

    @ViewBuilder
    private var aiSection: some View {
        Section("AI Integrations") {
            Toggle("Optional AI integrations (off)", isOn: .constant(false))
                .disabled(true)
        }
    }

    @ViewBuilder
    private var dataExportSection: some View {
        Section("Data Export") {
            Button("Export assignments (JSON)") {
                exportAssignments(format: .json)
            }
            Button("Export assignments (CSV)") {
                exportAssignments(format: .csv)
            }
            Button("Export focus sessions (JSON)") {
                exportFocusSessions(format: .json)
            }
            Button("Export focus sessions (CSV)") {
                exportFocusSessions(format: .csv)
            }
        }
    }

    @ViewBuilder
    private var addProfileSection: some View {
        Section("Add Profile") {
            TextField("New profile name", text: $newProfileName)
            Button("Create Profile") {
                createProfile()
            }
            .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Text("Log out")
            }
        } header: {
            Text("Account")
        } footer: {
            Text("You’ll return to onboarding. Local data stays on this device.")
        }
    }

    private func setActiveProfile(_ profile: Profile) {
        for item in profiles {
            item.activeProfile = item.id == profile.id
        }
        profileSession.select(profileId: profile.id)
        try? modelContext.save()
    }

    private func createProfile() {
        let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let profile = Profile(name: trimmed, createdAt: Date(), isDemo: false, activeProfile: true)
        modelContext.insert(profile)
        for item in profiles {
            item.activeProfile = item.id == profile.id
        }
        profileSession.select(profileId: profile.id)
        newProfileName = ""
        try? modelContext.save()
    }

    private var activeProfile: Profile? {
        guard let activeId = profileSession.activeProfileId else { return profiles.first }
        return profiles.first { $0.id == activeId }
    }

    private var themeDefaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupId) ?? .standard
    }


    private func loadCanvasSettings() {
        guard let profile = activeProfile else { return }
        canvasBaseURL = profile.canvasBaseURL ?? ""
        canvasClientId = profile.canvasClientId ?? ""
        canvasRedirectURI = profile.canvasRedirectURI ?? ""
        canvasScopes = profile.canvasScopes ?? "url:GET|/api/v1/*"
        canvasLimitedMode = profile.canvasLimitedMode
    }

    private func saveCanvasSettings() {
        guard let profile = activeProfile else { return }
        profile.canvasBaseURL = canvasBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.canvasClientId = canvasClientId.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.canvasRedirectURI = canvasRedirectURI.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.canvasScopes = canvasScopes.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.canvasLimitedMode = canvasLimitedMode
        try? modelContext.save()
    }

    private func connectCanvas() {
        saveCanvasSettings()
        guard let profile = activeProfile else { return }
        canvasAuth.startOAuth(profile: profile)
    }

    private func logoutCurrentProfile() {
        guard let activeId = profileSession.activeProfileId,
              let profile = profiles.first(where: { $0.id == activeId }) else {
            profileSession.clear()
            return
        }
        do {
            try CanvasTokenStore().delete(profileId: profile.id)
        } catch {
            // Best-effort token cleanup.
        }
        for item in profiles {
            item.activeProfile = false
        }
        profileSession.clear()
        try? modelContext.save()
    }

    private func weightSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(StudyTypography.caption)
            Slider(value: value, in: 0...1, step: 0.05)
        }
    }

    private enum ExportFormat {
        case json
        case csv

        var fileExtension: String {
            switch self {
            case .json:
                return "json"
            case .csv:
                return "csv"
            }
        }
    }

    private func exportAssignments(format: ExportFormat) {
        do {
            let assignments = try modelContext.fetch(FetchDescriptor<Assignment>())
            let data: Data
            switch format {
            case .json:
                data = try StorageExporter.assignmentsToJSON(assignments)
            case .csv:
                data = Data(StorageExporter.assignmentsToCSV(assignments).utf8)
            }
            let url = try writeExport(data: data, name: "StudyOS_Assignments", ext: format.fileExtension)
            exportURL = url
            showShareSheet = true
        } catch {
            presentExportError(error)
        }
    }

    private func exportFocusSessions(format: ExportFormat) {
        do {
            let sessions = try modelContext.fetch(FetchDescriptor<FocusSession>())
            let data: Data
            switch format {
            case .json:
                data = try StorageExporter.focusSessionsToJSON(sessions)
            case .csv:
                data = Data(StorageExporter.focusSessionsToCSV(sessions).utf8)
            }
            let url = try writeExport(data: data, name: "StudyOS_FocusSessions", ext: format.fileExtension)
            exportURL = url
            showShareSheet = true
        } catch {
            presentExportError(error)
        }
    }

    private func writeExport(data: Data, name: String, ext: String) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)_\(timestamp).\(ext)")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func presentExportError(_ error: Error) {
        exportErrorMessage = error.localizedDescription
        showExportError = true
    }
}

private struct ThemeOptionRow: View {
    let mode: ThemeMode

    private var theme: StudyTheme {
        switch mode {
        case .system, .light:
            return .chocolateTruffle
        case .dark:
            return .chiliSpice
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(theme.background)
                    .overlay(Circle().stroke(theme.separator, lineWidth: 1))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(theme.primary)
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(theme.accent)
                    .frame(width: 12, height: 12)
            }
            .accessibilityHidden(true)
            Text(mode.displayName)
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
