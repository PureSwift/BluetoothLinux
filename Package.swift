import PackageDescription

let package = Package(
    name: "BlueZ",
    dependencies: [
        .Package(url: "https://github.com/PureSwift/CBlueZ.git", majorVersion: 1),
        .Package(url: "https://github.com/PureSwift/SwiftFoundation.git", majorVersion: 1),
    ],
    targets: [
        Target(
            name: "ScanTest",
            dependencies: [.Target(name: "BlueZ")]),
        Target(
            name: "iBeaconTest",
            dependencies: [.Target(name: "BlueZ")]),
        Target(
            name: "L2CAPServerTest",
            dependencies: [.Target(name: "BlueZ")]),
        Target(
            name: "BlueZ")
    ]
)