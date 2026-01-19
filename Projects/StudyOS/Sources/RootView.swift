import SwiftUI
import SwiftData
import FeaturesOnboarding
import Features
import Storage

struct RootView: View {
    @EnvironmentObject private var profileSession: ProfileSession
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    var body: some View {
        Group {
            if profiles.isEmpty || profileSession.activeProfileId == nil {
                OnboardingView { profile in
                    profileSession.select(profileId: profile.id)
                }
            } else {
                AppShellView()
            }
        }
    }
}
