import ProjectDescription

let project = Project(
    name: "StudyOS",
    targets: [
        Target(
            name: "StudyOS",
            platform: .iOS,
            product: .app,
            bundleId: "com.studyos.app",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"]
        )
    ]
)
