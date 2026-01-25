import SwiftUI
import Storage
import SwiftData
import UIComponents

public struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()

    private let onComplete: (Profile) -> Void

    public init(onComplete: @escaping (Profile) -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            StudyColor.background.ignoresSafeArea()
            VStack(spacing: 24) {
                stepHeader
                ScrollView {
                    content
                }
                navigationControls
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .alert("Something went wrong", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var stepHeader: some View {
        VStack(spacing: 8) {
            StudyText("StudyOS", style: .title)
            StudyText("Step \(viewModel.step.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)", style: .caption, color: StudyColor.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .welcome:
            welcomeView
        case .permissions:
            permissionsView
        case .mode:
            modeView
        case .profile:
            profileView
        case .finish:
            finishView
        }
    }

    private var welcomeView: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 16) {
                StudyText("Welcome to StudyOS", style: .headline)
                StudyText("Plan assignments, sync Canvas, and stay on top of your week with offline-first tools.", style: .body, color: StudyColor.secondaryText)
            }
        }
    }

    private var permissionsView: some View {
        VStack(spacing: 12) {
            permissionCard(
                title: "Notifications",
                detail: "Get reminders for deadlines and focus sessions.",
                status: viewModel.notificationsStatus,
                actionTitle: "Allow"
            ) {
                Task { await viewModel.requestNotifications() }
            }
            permissionCard(
                title: "Calendar",
                detail: "Detect conflicts and export study blocks.",
                status: viewModel.calendarStatus,
                actionTitle: "Allow"
            ) {
                Task { await viewModel.requestCalendar() }
            }
            StudyCard {
                VStack(alignment: .leading, spacing: 12) {
                    StudyText("Files", style: .headline)
                    StudyText("Import syllabi, PDFs, and notes via the document picker.", style: .body, color: StudyColor.secondaryText)
                    StudyChip(text: "On demand")
                }
            }
            StudyCard {
                VStack(alignment: .leading, spacing: 12) {
                    StudyText("Location (optional)", style: .headline)
                    StudyText("Enable leave-now alerts when classes are on campus.", style: .body, color: StudyColor.secondaryText)
                    Toggle("Enable location alerts", isOn: $viewModel.wantsLocation)
                        .onChange(of: viewModel.wantsLocation) { _ in
                            viewModel.requestLocationIfNeeded()
                        }
                        .accessibilityLabel("Enable location alerts")
                    StudyChip(text: statusLabel(viewModel.locationStatus))
                }
            }
        }
    }

    private var modeView: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 16) {
                StudyText("Choose a setup mode", style: .headline)
                ForEach(OnboardingViewModel.Mode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.selectedMode = mode
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                                .font(StudyTypography.body)
                            Spacer()
                            if viewModel.selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(StudyColor.coolAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mode.rawValue)
                }
            }
        }
    }

    private var profileView: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 16) {
                StudyText("Create your profile", style: .headline)
                TextField("Profile name", text: $viewModel.profileName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Profile name")

                if viewModel.selectedMode == .canvas {
                    TextField("Canvas base URL (e.g., https://school.instructure.com)", text: $viewModel.canvasBaseURL)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityLabel("Canvas base URL")
                }

                if viewModel.selectedMode == .ical {
                    TextField("iCal feed URL (optional)", text: $viewModel.icalFeedURL)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityLabel("iCal feed URL")
                }

                StudyText("You can add more profiles anytime from Settings.", style: .caption, color: StudyColor.secondaryText)
            }
        }
    }

    private var finishView: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 16) {
                StudyText("You’re ready to go", style: .headline)
                StudyText("StudyOS will sync when you connect and keep your plan available offline.", style: .body, color: StudyColor.secondaryText)
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            if viewModel.step != .welcome {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Back")
            }
            Spacer()
            StudyButton(primaryButtonTitle) {
                goForward()
            }
            .frame(maxWidth: 220)
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.step {
        case .finish:
            return "Enter StudyOS"
        case .profile:
            return "Continue"
        default:
            return "Next"
        }
    }

    private func goBack() {
        guard let previous = OnboardingViewModel.Step(rawValue: viewModel.step.rawValue - 1) else { return }
        viewModel.step = previous
    }

    private func goForward() {
        if viewModel.step == .finish {
            completeOnboarding()
            return
        }
        if viewModel.step == .profile {
            viewModel.step = .finish
            return
        }
        guard let next = OnboardingViewModel.Step(rawValue: viewModel.step.rawValue + 1) else { return }
        viewModel.step = next
    }

    private func completeOnboarding() {
        do {
            switch viewModel.selectedMode {
            case .demo:
                let profiles = try DemoDataLoader.seed(into: modelContext)
                if let profile = profiles.first {
                    onComplete(profile)
                }
            case .canvas, .ical:
                let name = viewModel.profileName.trimmingCharacters(in: .whitespacesAndNewlines)
                let profile = Profile(
                    name: name.isEmpty ? "Student" : name,
                    createdAt: Date(),
                    isDemo: false,
                    activeProfile: true,
                    canvasBaseURL: viewModel.canvasBaseURL.isEmpty ? nil : viewModel.canvasBaseURL,
                    canvasClientId: nil,
                    canvasRedirectURI: nil,
                    icalFeedURL: viewModel.icalFeedURL.isEmpty ? nil : viewModel.icalFeedURL
                )
                modelContext.insert(profile)
                try modelContext.save()
                onComplete(profile)
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func permissionCard(
        title: String,
        detail: String,
        status: OnboardingViewModel.PermissionStatus,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 12) {
                StudyText(title, style: .headline)
                StudyText(detail, style: .body, color: StudyColor.secondaryText)
                HStack {
                    StudyChip(text: statusLabel(status))
                    Spacer()
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                        .accessibilityLabel(actionTitle)
                }
            }
        }
    }

    private func statusLabel(_ status: OnboardingViewModel.PermissionStatus) -> String {
        switch status {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .unknown:
            return "Not set"
        }
    }
}
