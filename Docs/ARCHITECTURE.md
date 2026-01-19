# Architecture

StudyOS follows an iOS-only SwiftUI architecture using MVVM and a Repository pattern.

## Layers
- UI layer in SwiftUI with feature modules.
- View models per feature with async/await and typed errors.
- Repositories abstract local (SwiftData) and sync sources.
- Sync engines manage Canvas and calendar ingestion.

## Packages
- Core: shared utilities, configs, logging.
- Storage: SwiftData models and repositories.
- Canvas: OAuth and API client.
- Planner: scheduling engine.
- UIComponents: theme and reusable UI.
- Features: feature screens.
