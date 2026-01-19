import Core
import Features
import SwiftData
import SwiftUI
import Storage
import UIComponents

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

    public init() {}

    public var body: some View {
        List {
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

            Section("Sync") {
                NavigationLink("Sync Health") {
                    SyncHealthView()
                }
            }

            Section("Planning") {
                NavigationLink("Templates") {
                    TemplateLibraryView()
                }
            }

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
            }

            Section("Priority Weights") {
                weightSlider(title: "Due soon", value: $dueSoonWeight)
                weightSlider(title: "Effort", value: $effortWeight)
                weightSlider(title: "Weight", value: $weightWeight)
                weightSlider(title: "Status", value: $statusWeight)
                weightSlider(title: "Course importance", value: $courseWeight)
            }

            Section("AI Integrations") {
                Toggle("Optional AI integrations (off)", isOn: .constant(false))
                    .disabled(true)
            }

            Section("Add Profile") {
                TextField("New profile name", text: $newProfileName)
                Button("Create Profile") {
                    createProfile()
                }
                .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            loadCanvasSettings()
        }
        .onChange(of: profileSession.activeProfileId) { _ in
            loadCanvasSettings()
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

    private func weightSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(StudyTypography.caption)
            Slider(value: value, in: 0...1, step: 0.05)
        }
    }
}
