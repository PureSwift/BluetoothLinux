// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "BluetoothLinux",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "BluetoothLinux",
            targets: ["BluetoothLinux"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/swift-system.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/Socket.git",
            .branch("main")
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin.git", 
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "BluetoothLinux",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth"
                ),
                "CBluetoothLinux",
                .product(
                    name: "SystemPackage",
                    package: "swift-system"
                ),
                "Socket"
            ]
        ),
        .target(
            name: "CBluetoothLinux"
        ),
        .target(
            name: "CBluetoothLinuxTest"
        ),
        .testTarget(
            name: "BluetoothLinuxTests",
            dependencies: [
                "BluetoothLinux",
                "CBluetoothLinuxTest"
            ]
        )
    ]
)
