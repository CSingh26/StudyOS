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
}
