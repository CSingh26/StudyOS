// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Planner", targets: ["Planner"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Planner",
            dependencies: [
                .product(name: "Core", package: "Core")
            ]
        )
    ]
)
