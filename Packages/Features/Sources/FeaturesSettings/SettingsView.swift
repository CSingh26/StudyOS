import SwiftUI
import SwiftData
import Storage
import UIComponents
import Features

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var newProfileName: String = ""

    public init() {}

    public var body: some View {
        List {
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

            Section("Add Profile") {
                TextField("New profile name", text: $newProfileName)
                Button("Create Profile") {
                    createProfile()
                }
                .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .listStyle(.insetGrouped)
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
}
