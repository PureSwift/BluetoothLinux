# BluetoothLinux

Pure Swift Bluetooth Stack for Linux

Does not require [BlueZ](https://www.bluez.org), communicates directly with the Linux kernel and Bluetooth controller. 

# Installation

1. Install [Helper C Headers](https://github.com/PureSwift/CSwiftBluetoothLinux)
1. `swift build`

# Tests

I recommend [LightBlue Explorer](https://itunes.apple.com/us/app/lightblue-explorer-bluetooth/id557428110?mt=8) and [Locate Beacon](https://itunes.apple.com/us/app/locate-beacon/id738709014?mt=8) to verify the iBeacon is advertising. The iBeacon test case is already configured to use a UUID that is preinstalled in the *Locate Beacon* app.

# Troubleshooting

Do not test in Parallels or VMware with the built in Bluetooth adapter found in Macs. You can, however, use VMWare or Parallels, with a Linux compatible BLE USB adapter plugged in.

For best results, test with Swift 3.0.2 on an ARM board running Linux (e.g. BeagleBoneBlack, Orange Pi) and a Linux comaptible Bluetooth dongle (e.g. CSR8510 A10).

# See Also

- [Bluetooth](https://github.com/PureSwift/Bluetooth) - Pure Swift Bluetooth Definitions
- [GATT](https://github.com/PureSwift/GATT) - Bluetooth Generic Attribute Profile (GATT) for Swift
- [SwiftFoundation](https://github.com/PureSwift/SwiftFoundation) - Cross-Platform, Protocol-Oriented Programming base library to complement the Swift Standard Library.
- [Cacao](https://github.com/PureSwift/Cacao) - Pure Swift Cross-platform UIKit
- [Silica](https://github.com/PureSwift/Silica) - Pure Swift CoreGraphics (Quartz2D) implementation
- [Predicate](https://github.com/PureSwift/Predicate) - Pure Swift Predicate implementation 