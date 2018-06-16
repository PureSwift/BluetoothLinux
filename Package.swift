import PackageDescription

let package = Package(
    name: "BluetoothLinux",
    targets: [
        Target(
            name: "BluetoothLinux",
            dependencies: [
                .Target(name: "CSwiftBluetoothLinux")
            ]),
        Target(
            name: "CSwiftBluetoothLinux"),
        Target(
            name: "CSwiftBluetoothLinuxTest"),
        Target(
            name: "BluetoothLinuxTests",
            dependencies: [
                .Target(name: "BluetoothLinux"),
                .Target(name: "CSwiftBluetoothLinuxTest")
            ])
    ],
    dependencies: [
        .Package(url: "https://github.com/PureSwift/Bluetooth.git", majorVersion: 2)
    ]
)
