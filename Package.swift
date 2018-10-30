// swift-tools-version:4.1
import PackageDescription

_ = Package(name: "BluetoothLinux",
            products: [
                .library(
                    name: "BluetoothLinux",
                    targets: ["BluetoothLinux"]
                )
            ],
            dependencies: [
                .package(url: "https://github.com/PureSwift/Bluetooth.git", .branch("master"))
            ],
            targets: [
                .target(name: "BluetoothLinux", dependencies: ["Bluetooth", "CSwiftBluetoothLinux"]),
                .target(name: "CSwiftBluetoothLinux"),
                .target(name: "CSwiftBluetoothLinuxTest"),
                .testTarget(name: "BluetoothLinuxTests", dependencies: ["BluetoothLinux", "CSwiftBluetoothLinuxTest"])
            ],
            swiftLanguageVersions: [4])
