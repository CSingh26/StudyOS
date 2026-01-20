import ProjectDescription

let destinations: Destinations = .iOS
let deploymentTargets = DeploymentTargets.iOS("17.0")

let project = Project(
    name: "StudyOS",
    packages: [
        .package(path: "../../Packages/Core"),
        .package(path: "../../Packages/Storage"),
        .package(path: "../../Packages/Canvas"),
        .package(path: "../../Packages/Planner"),
        .package(path: "../../Packages/UIComponents"),
        .package(path: "../../Packages/Features")
    ],
    targets: [
        .target(
            name: "StudyOS",
            destinations: destinations,
            product: .app,
            bundleId: "com.studyos.app",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("StudyOS"),
                "UIBackgroundModes": .array([.string("fetch"), .string("processing")]),
                "BGTaskSchedulerPermittedIdentifiers": .array([
                    .string("com.studyos.refresh"),
                    .string("com.studyos.processing")
                ]),
                "NSSupportsLiveActivities": .boolean(true),
                "NSCalendarsUsageDescription": .string("StudyOS uses calendar access to detect conflicts and export study blocks."),
                "NSLocationWhenInUseUsageDescription": .string("StudyOS uses your location for optional leave-now alerts."),
                "NSCameraUsageDescription": .string("StudyOS uses the camera to scan notes and extract text."),
                "NSFaceIDUsageDescription": .string("StudyOS uses Face ID to lock the app and protect your data."),
                "UISupportsDocumentBrowser": .boolean(false)
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .file(path: "Resources/Entitlements/StudyOS.entitlements"),
            dependencies: [
                .package(product: "Core"),
                .package(product: "Storage"),
                .package(product: "Canvas"),
                .package(product: "Planner"),
                .package(product: "UIComponents"),
                .package(product: "Features"),
                .package(product: "FeaturesOnboarding"),
                .package(product: "FeaturesToday"),
                .package(product: "FeaturesAssignments"),
                .package(product: "FeaturesCalendar"),
                .package(product: "FeaturesVault"),
                .package(product: "FeaturesGrades"),
                .package(product: "FeaturesSettings"),
                .package(product: "FeaturesCollaboration"),
                .target(name: "StudyOSWidgets"),
                .target(name: "StudyOSLiveActivities"),
                .target(name: "SaveToStudyOS")
            ]
        ),
        .target(
            name: "StudyOSWidgets",
            destinations: destinations,
            product: .appExtension,
            bundleId: "com.studyos.app.widgets",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension")
                ])
            ]),
            sources: ["Widgets/**"],
            resources: [],
            entitlements: .file(path: "Resources/Entitlements/StudyOSWidgets.entitlements"),
            dependencies: [
                .package(product: "UIComponents"),
                .package(product: "Storage")
            ]
        ),
        .target(
            name: "StudyOSLiveActivities",
            destinations: destinations,
            product: .appExtension,
            bundleId: "com.studyos.app.liveactivities",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension")
                ])
            ]),
            sources: ["LiveActivities/**"],
            resources: [],
            entitlements: .file(path: "Resources/Entitlements/StudyOSLiveActivities.entitlements"),
            dependencies: [
                .package(product: "UIComponents"),
                .package(product: "Storage")
            ]
        ),
        .target(
            name: "SaveToStudyOS",
            destinations: destinations,
            product: .appExtension,
            bundleId: "com.studyos.app.share",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Save to StudyOS"),
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.share-services"),
                    "NSExtensionPrincipalClass": .string("ShareViewController")
                ])
            ]),
            sources: ["ShareExtension/**"],
            resources: [],
            entitlements: .file(path: "Resources/Entitlements/SaveToStudyOS.entitlements"),
            dependencies: [
                .package(product: "Core"),
                .package(product: "Storage"),
                .package(product: "UIComponents")
            ]
        ),
        .target(
            name: "StudyOSTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "com.studyos.appTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "StudyOS"),
                .package(product: "Planner"),
                .package(product: "Core"),
                .package(product: "Canvas")
            ]
        ),
        .target(
            name: "StudyOSUITests",
            destinations: destinations,
            product: .uiTests,
            bundleId: "com.studyos.appUITests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["UITests/**"],
            resources: [],
            dependencies: [
                .target(name: "StudyOS")
            ]
        )
    ],
    additionalFiles: [
        "Resources/Entitlements/**"
    ]
)
