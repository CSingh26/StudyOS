import ProjectDescription

let deploymentTarget = DeploymentTarget.iOS(targetVersion: "17.0", devices: [.iphone])
let appGroupId = "group.com.studyos.app"

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
        Target(
            name: "StudyOS",
            platform: .iOS,
            product: .app,
            bundleId: "com.studyos.app",
            deploymentTarget: deploymentTarget,
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
        Target(
            name: "StudyOSWidgets",
            platform: .iOS,
            product: .appExtension,
            bundleId: "com.studyos.app.widgets",
            deploymentTarget: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
                    "NSExtensionPrincipalClass": .string("WidgetKit.WidgetExtension")
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
        Target(
            name: "StudyOSLiveActivities",
            platform: .iOS,
            product: .appExtension,
            bundleId: "com.studyos.app.liveactivities",
            deploymentTarget: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
                    "NSExtensionPrincipalClass": .string("WidgetKit.WidgetExtension")
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
        Target(
            name: "SaveToStudyOS",
            platform: .iOS,
            product: .appExtension,
            bundleId: "com.studyos.app.share",
            deploymentTarget: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.share-services"),
                    "NSExtensionPrincipalClass": .string("ShareViewController")
                ])
            ]),
            sources: ["ShareExtension/**"],
            resources: [],
            entitlements: .file(path: "Resources/Entitlements/SaveToStudyOS.entitlements"),
            dependencies: [
                .package(product: "Storage"),
                .package(product: "UIComponents")
            ]
        ),
        Target(
            name: "StudyOSTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.studyos.appTests",
            deploymentTarget: deploymentTarget,
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
        Target(
            name: "StudyOSUITests",
            platform: .iOS,
            product: .uiTests,
            bundleId: "com.studyos.appUITests",
            deploymentTarget: deploymentTarget,
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
