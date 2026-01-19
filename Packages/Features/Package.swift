// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Features", targets: ["Features"]),
        .library(name: "FeaturesOnboarding", targets: ["FeaturesOnboarding"]),
        .library(name: "FeaturesToday", targets: ["FeaturesToday"]),
        .library(name: "FeaturesAssignments", targets: ["FeaturesAssignments"]),
        .library(name: "FeaturesCalendar", targets: ["FeaturesCalendar"]),
        .library(name: "FeaturesVault", targets: ["FeaturesVault"]),
        .library(name: "FeaturesGrades", targets: ["FeaturesGrades"]),
        .library(name: "FeaturesSettings", targets: ["FeaturesSettings"]),
        .library(name: "FeaturesCollaboration", targets: ["FeaturesCollaboration"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../UIComponents"),
        .package(path: "../Planner"),
        .package(path: "../Storage"),
        .package(path: "../Canvas")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesOnboarding",
            dependencies: [
                "Features",
                .product(name: "Core", package: "Core"),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "Storage", package: "Storage")
            ]
        ),
        .target(
            name: "FeaturesToday",
            dependencies: [
                "Features",
                .product(name: "Core", package: "Core"),
                .product(name: "Planner", package: "Planner"),
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesAssignments",
            dependencies: [
                "Features",
                .product(name: "Core", package: "Core"),
                .product(name: "Storage", package: "Storage"),
                .product(name: "Planner", package: "Planner"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesCalendar",
            dependencies: [
                "Features",
                .product(name: "Core", package: "Core"),
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesVault",
            dependencies: [
                "Features",
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesGrades",
            dependencies: [
                "Features",
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesSettings",
            dependencies: [
                "Features",
                .product(name: "Core", package: "Core"),
                .product(name: "Canvas", package: "Canvas"),
                .product(name: "Planner", package: "Planner"),
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .target(
            name: "FeaturesCollaboration",
            dependencies: [
                "Features",
                .product(name: "Storage", package: "Storage"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        )
    ]
)
