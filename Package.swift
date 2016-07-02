import PackageDescription

let package = Package(
    name: "BluetoothLinux",
    targets: [
        Target(
            name: "ScanTest",
            dependencies: [.Target(name: "BluetoothLinux")]),
        Target(
            name: "iBeaconTest",
            dependencies: [.Target(name: "BluetoothLinux")]),
        Target(
            name: "L2CAPServerTest",
            dependencies: [.Target(name: "BluetoothLinux")]),
        Target(
            name: "GATTServerTest",
            dependencies: [.Target(name: "BluetoothLinux")]),
        Target(
            name: "BluetoothLinux")
    ],
    dependencies: [
        .Package(url: "https://github.com/PureSwift/Bluetooth.git", majorVersion: 1),
        .Package(url: "https://github.com/PureSwift/CSwiftBluetoothLinux.git", majorVersion: 1)
    ],
    exclude: ["Xcode", "Sources/UnitTests"]
)
