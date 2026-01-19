// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Canvas",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Canvas", targets: ["Canvas"])
    ],
    targets: [
        .target(
            name: "Canvas",
            dependencies: []
        )
    ]
)
