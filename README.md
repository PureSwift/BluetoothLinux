![BluetoothLinux](https://github.com/PureSwift/BluetoothLinux/raw/master/Assets/PureSwiftBluetoothLinux.png)

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![Release][release-badge]][release-url]
[![Build Status][build-status-badge]][build-status-url]
[![License][mit-badge]][mit-url]
[![CodeBeat][codebeat-badge]][codebeat-url]

[![SPM compatible][spm-badge]][spm-url]
[![Carthage compatible][carthage-badge]][carthage-url]

Pure Swift Bluetooth Stack for Linux

Does not require [BlueZ](https://www.bluez.org), communicates directly with the Linux kernel and Bluetooth controller. 

## Usage

```swift
import Bluetooth
import BluetoothLinux

guard let adapter = try? Adapter()
    else { Error("No Bluetooth adapters found") }

print("Found Bluetooth adapter with device ID: \(adapter.identifier)")

let iBeaconUUID = Foundation.UUID(rawValue: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!

do { try adapter.enableBeacon(uuid: iBeaconUUID, major: 1, minor: 1, rssi: -29) }
    
catch { print("Error enabling iBeacon: \(error)") }
```

## Installation

### Swift Package Manager

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/PureSwift/BluetoothLinux.git", majorVersion: 2)
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

## Testing

I recommend [LightBlue Explorer](https://itunes.apple.com/us/app/lightblue-explorer-bluetooth/id557428110?mt=8) and [Locate Beacon](https://itunes.apple.com/us/app/locate-beacon/id738709014?mt=8) to verify the iBeacon is advertising. The iBeacon test case is already configured to use a UUID that is preinstalled in the *Locate Beacon* app.

## Troubleshooting

Do not test in Parallels or VMware with the built in Bluetooth adapter found in Macs. You can, however, use VMWare or Parallels, with a Linux compatible Bluetooth LE USB adapter plugged in. VirtualBox will work with the builtin adapter on Macs.

For best results, test with Swift 3.0.2 on an ARM board running Linux (e.g. BeagleBoneBlack, Raspberry Pi, Orange Pi, etc) and a Linux comaptible Bluetooth dongle (e.g. CSR8510 A10).

## See Also

- [Bluetooth](https://github.com/PureSwift/Bluetooth) - Pure Swift Bluetooth Definitions.
- [GATT](https://github.com/PureSwift/GATT) - Bluetooth Generic Attribute Profile (GATT) for Swift
- [SwiftFoundation](https://github.com/PureSwift/SwiftFoundation) - Cross-Platform, Protocol-Oriented Programming base library to complement the Swift Standard Library.
- [Cacao](https://github.com/PureSwift/Cacao) - Pure Swift Cross-platform UIKit
- [Silica](https://github.com/PureSwift/Silica) - Pure Swift CoreGraphics (Quartz2D) implementation
- [Predicate](https://github.com/PureSwift/Predicate) - Pure Swift Predicate implementation 

License
-------

**BluetoothLinux** is released under the MIT license. See LICENSE for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.2-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/platform-linux-lightgrey.svg
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[build-status-badge]: https://travis-ci.org/PureSwift/BluetoothLinux.svg?branch=master
[build-status-url]: https://travis-ci.org/PureSwift/BluetoothLinux
[release-badge]: https://img.shields.io/github/release/PureSwift/BluetoothLinux
[release-url]: https://github.com/PureSwift/BluetoothLinux/releases
[spm-badge]: https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat
[spm-url]: https://github.com/apple/swift-package-manager
[carthage-badge]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
[carthage-url]: https://github.com/Carthage/Carthage
[codebeat-badge]: https://codebeat.co/badges/3eaf4fc3-6514-4f2d-83d5-ffd879f319d2
[codebeat-url]: https://codebeat.co/projects/github-com-pureswift-bluetoothlinux-master
