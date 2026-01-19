// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Storage", targets: ["Storage"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: [
                .product(name: "Core", package: "Core")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
