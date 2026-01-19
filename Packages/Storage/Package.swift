// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Storage", targets: ["Storage"])
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: []
        )
    ]
)
