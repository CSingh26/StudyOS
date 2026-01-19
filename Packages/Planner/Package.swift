// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Planner", targets: ["Planner"])
    ],
    targets: [
        .target(
            name: "Planner",
            dependencies: []
        )
    ]
)
