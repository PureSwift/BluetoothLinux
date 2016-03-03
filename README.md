# BluetoothLinux
Pure Swift Bluetooth Stack for Linux

Does not require [BlueZ](https://www.bluez.org), communicates directly with the Linux kernel. 

![Screenshot](http://i.imgur.com/0EPoVEr.png)

# Dependencies

1. SwiftFoundation [dependencies](https://github.com/PureSwift/SwiftFoundation/blob/develop/README.md#compiling-on-ubuntu)
2. Install [Helper C Headers](https://github.com/PureSwift/CSwiftBluetoothLinux)

# Unit Tests

I recommend [LightBlue Explorer](https://itunes.apple.com/us/app/lightblue-explorer-bluetooth/id557428110?mt=8) and [Locate Beacon](https://itunes.apple.com/us/app/locate-beacon/id738709014?mt=8) to verify the iBeacon is advertising. The iBeacon test case is already configured to use a UUID that is preinstalled in the *Locate Beacon* app.

## Troubleshooting
- Do not test in Parallels or VMware with the built in Bluetooth adapter found in Macs. You can, however, use VMWare or Parallels, with a Linux compatible BLE USB adapter plugged in.