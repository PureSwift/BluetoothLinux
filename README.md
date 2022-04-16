![BluetoothLinux](https://github.com/PureSwift/BluetoothLinux/raw/master/Assets/PureSwiftBluetoothLinux.png)

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![Release][release-badge]][release-url]
[![License][mit-badge]][mit-url]

Pure Swift Bluetooth Stack for Linux

Does not require [BlueZ](https://www.bluez.org) userland library, communicates directly with the Linux kernel Bluetooth subsystem. 

## Usage

```swift
import Bluetooth
import BluetoothLinux

guard let hostController = BluetoothLinux.HostController.default
    else { fatalError("No Bluetooth adapters found") }
let uuid = UUID(rawValue: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
let beacon = AppleBeacon(uuid: uuid, major: 1, minor: 1, rssi: -29)
do { try hostController.iBeacon(beacon) }
catch { print("Error enabling iBeacon: \(error)") }
```

## Installation

### Swift Package Manager

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(
			url: "https://github.com/PureSwift/BluetoothLinux.git",
    		.branch("master")
    		)
        ]
)
```

## Documentation

Documentation can be generated with [Jazzy](https://github.com/realm/jazzy).

```
swift package generate-xcodeproj
jazzy
```

Read the documentation [here](http://pureswift.github.io/BluetoothLinux/docs/). For more information, see the [gh-pages](https://github.com/PureSwift/BluetoothLinux/tree/gh-pages) branch.

## Troubleshooting

Do not test in Parallels or VMware with the built in Bluetooth adapter found in Macs. You can, however, use VMWare or Parallels, with a Linux compatible Bluetooth LE USB adapter plugged in. 

## See Also

- [Bluetooth](https://github.com/PureSwift/Bluetooth) - Pure Swift Bluetooth Definitions.
- [GATT](https://github.com/PureSwift/GATT) - Bluetooth Generic Attribute Profile (GATT) for Swift
- [Silica](https://github.com/PureSwift/Silica) - Pure Swift CoreGraphics (Quartz2D) implementation
- [Predicate](https://github.com/PureSwift/Predicate) - Pure Swift Predicate implementation 

License
-------

**BluetoothLinux** is released under the MIT license. See LICENSE for details.

[swift-badge]: https://img.shields.io/badge/Swift-5.6-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/platform-linux-lightgrey.svg
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[release-badge]: https://img.shields.io/github/release/PureSwift/BluetoothLinux.svg
[release-url]: https://github.com/PureSwift/BluetoothLinux/releases
