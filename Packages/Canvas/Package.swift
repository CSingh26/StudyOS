// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Canvas",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Canvas", targets: ["Canvas"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Canvas",
            dependencies: [
                .product(name: "Core", package: "Core")
            ]
        )
    ]
)
