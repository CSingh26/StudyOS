// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "UIComponents", targets: ["UIComponents"])
    ],
    targets: [
        .target(
            name: "UIComponents",
            dependencies: []
        )
    ]
)
