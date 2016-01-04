# SwiftBlueZ
Swift wrapper for Linux Bluetooth C API (BlueZ)

![Screenshot](http://i.imgur.com/0EPoVEr.png)

# Dependencies

1. SwiftFoundation [dependencies](https://github.com/PureSwift/SwiftFoundation/blob/develop/README.md#compiling-on-ubuntu)
2. `sudo apt-get install libbluetooth-dev`

# Unit Tests

```
swift build
sudo .build/debug/UnitTests
```

Then `ctrl + c` when you're finished.

I recommend [LightBlue Explorer](https://itunes.apple.com/us/app/lightblue-explorer-bluetooth/id557428110?mt=8) to verify the iBeacon is advertising.

## Note
Do NOT test with Parallels or VMware, and please do not create issues regarding those VMs.