import SwiftUI
import SwiftData
import FeaturesOnboarding
import Features
import Storage
import Core
import UIComponents

struct RootView: View {
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLockManager = AppLockManager()
    @AppStorage(AppConstants.appLockEnabledKey) private var appLockEnabled: Bool = false

    var body: some View {
        ZStack {
            if needsOnboarding {
                OnboardingView { profile in
                    profileSession.select(profileId: profile.id)
                }
            } else {
                AppShellView()
            }

            if shouldShowLockOverlay {
                AppLockOverlay {
                    Task { await appLockManager.unlockIfNeeded() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: scenePhase) { phase in
            guard !needsOnboarding else { return }
            switch phase {
            case .active:
                Task { await appLockManager.unlockIfNeeded() }
            case .background:
                appLockManager.lockIfNeeded()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .onChange(of: appLockEnabled) { enabled in
            if !enabled {
                appLockManager.disableLock()
            } else if !needsOnboarding {
                appLockManager.lockIfNeeded()
            }
        }
        .task {
            if appLockEnabled && !needsOnboarding {
                await appLockManager.unlockIfNeeded()
            }
        }
    }

    private var needsOnboarding: Bool {
        profiles.isEmpty || profileSession.activeProfileId == nil
    }

    private var shouldShowLockOverlay: Bool {
        appLockEnabled && !needsOnboarding && appLockManager.isLocked
    }
}

private struct AppLockOverlay: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(StudyColor.coolAccent)
                Text("StudyOS is locked")
                    .font(StudyTypography.headline)
                Text("Unlock with Face ID or device passcode.")
                    .font(StudyTypography.caption)
                    .foregroundColor(StudyColor.secondaryText)
                Button("Unlock") {
                    onUnlock()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("StudyOS locked. Unlock to continue.")
        }
    }
}
