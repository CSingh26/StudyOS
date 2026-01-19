import Core
import Features
import Storage
import SwiftData
import SwiftUI
import UIComponents
import UniformTypeIdentifiers

public struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var showFileImporter = false
    @State private var feedURLText = ""
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    private let importService = ICalImportService()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            StudyCard {
                VStack(alignment: .leading, spacing: 12) {
                    StudyText("iCal Import", style: .headline)
                    StudyText("Import .ics files or subscribe to a feed URL.", style: .body, color: StudyColor.secondaryText)

                    HStack {
                        StudyButton("Import .ics") {
                            showFileImporter = true
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Feed URL", text: $feedURLText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)

                        HStack {
                            Button("Subscribe") {
                                updateFeedURL()
                            }
                            .buttonStyle(.bordered)

                            Button(isRefreshing ? "Refreshing..." : "Refresh Feed") {
                                Task { await refreshFeed() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isRefreshing)
                        }

                        if let lastSync = activeProfile?.lastIcalSyncAt {
                            StudyText("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))", style: .caption, color: StudyColor.secondaryText)
                        }
                    }
                }
            }

            if events.isEmpty {
                EmptyStateView(title: "No events yet", message: "Import an .ics file to see your schedule here.")
            } else {
                List {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.title)
                                .font(StudyTypography.headline)
                            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(StudyTypography.caption)
                                .foregroundColor(StudyColor.secondaryText)
                            if !event.location.isEmpty {
                                Text(event.location)
                                    .font(StudyTypography.caption)
                                    .foregroundColor(StudyColor.secondaryText)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(16)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.calendar, .data]) { result in
            switch result {
            case .success(let url):
                importFile(from: url)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .alert("Import failed", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            feedURLText = activeProfile?.icalFeedURL ?? ""
        }
    }

    private var activeProfile: Profile? {
        guard let activeId = profileSession.activeProfileId else { return profiles.first }
        return profiles.first { $0.id == activeId }
    }

    private func importFile(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: url)
            try importService.importEvents(data: data, context: modelContext, source: .ical)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateFeedURL() {
        guard let profile = activeProfile else { return }
        let trimmed = feedURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.icalFeedURL = trimmed.isEmpty ? nil : trimmed
        try? modelContext.save()
    }

    private func refreshFeed() async {
        guard let profile = activeProfile,
              let urlString = profile.icalFeedURL,
              let url = URL(string: urlString) else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await importService.refreshFeed(url: url, context: modelContext, profile: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
