import PackageDescription

let package = Package(
    name: "SwiftBlueZ",
    dependencies: [
        .Package(url: "https://github.com/PureSwift/CBlueZ.git", majorVersion: 1),
    ]
)