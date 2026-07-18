// swift-tools-version:6.0
import PackageDescription
import class Foundation.ProcessInfo

// force building as dynamic library
let dynamicLibrary = ProcessInfo.processInfo.environment["SWIFT_BUILD_DYNAMIC_LIBRARY"] != nil
let libraryType: PackageDescription.Product.Library.LibraryType? = dynamicLibrary ? .dynamic : nil

var package = Package(
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
            type: libraryType,
            targets: ["BluetoothLinux"]
        ),
        .executable(
            name: "hcitool",
            targets: ["hcitool"]
        ),
        .executable(
            name: "hciconfig",
            targets: ["hciconfig"]
        ),
        .executable(
            name: "gatttool",
            targets: ["gatttool"]
        ),
        .executable(
            name: "gattserver",
            targets: ["gattserver"]
        ),
        .executable(
            name: "beacon",
            targets: ["beacon"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/Socket.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.5.0"
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
                .product(
                    name: "Socket",
                    package: "Socket"
                ),
                "CBluetoothLinux"
            ],
            swiftSettings: [
                // Syscall mocking for unit tests (see Internal/Mocking.swift),
                // same pattern as swift-system.
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        ),
        .executableTarget(
            name: "hcitool",
            dependencies: [
                "BluetoothLinux",
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .executableTarget(
            name: "hciconfig",
            dependencies: [
                "BluetoothLinux",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .executableTarget(
            name: "gatttool",
            dependencies: [
                "BluetoothLinux",
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .executableTarget(
            name: "gattserver",
            dependencies: [
                "BluetoothLinux",
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .executableTarget(
            name: "beacon",
            dependencies: [
                "BluetoothLinux",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
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
                "CBluetoothLinuxTest",
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                )
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        )
    ]
)

// SwiftPM command plugins are only supported by Swift version 5.6 and later.
#if swift(>=5.6)
let buildDocs = ProcessInfo.processInfo.environment["BUILDING_FOR_DOCUMENTATION_GENERATION"] != nil
if buildDocs {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ]
}
#endif
