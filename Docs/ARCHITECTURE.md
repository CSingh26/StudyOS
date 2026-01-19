# Architecture

StudyOS is an iOS-only SwiftUI app built around MVVM and a repository pattern, optimized for offline-first usage and privacy.

## Layers
- **UI (SwiftUI)**: Feature screens (Onboarding, Today, Assignments, Calendar, Vault, Grades, Settings).
- **View Models**: State + async/await orchestration; minimal side effects.
- **Repositories**: Storage access through SwiftData models and ModelContext.
- **Sync Engines**: Canvas sync, iCal import, background refresh via BGTaskScheduler.

## Packages
- **Core**: Constants, logging (OSLog), network utilities, Keychain, widget snapshot store.
- **Storage**: SwiftData models + storage controller; demo data seeding.
- **Canvas**: OAuth + Canvas API client (PKCE, endpoints, DTOs).
- **Planner**: Priority scoring, scheduling engine, heatmap, learning estimates.
- **UIComponents**: Theme system + reusable views.
- **Features**: Feature modules split into sub-targets.

## Data Flow
1. Local SwiftData store is the source of truth.
2. Canvas sync fetches remote data → maps DTOs → stores in SwiftData.
3. UI reads from SwiftData using `@Query` and updates instantly.
4. Widgets read from an App Group snapshot JSON written by the app.

## Background Work
- **BGAppRefreshTask** and **BGProcessingTask** schedule Canvas sync.
- Notifications are scheduled for deadlines, study blocks, and classes.
- Optional Leave Now alerts use MapKit travel time.

## Privacy & Security
- No custom backend.
- OAuth tokens stored in Keychain.
- Optional iCloud sharing via CloudKit.
