//
//  Integer.swift
//  BluetoothLinux
//

internal extension UInt16 {

    init(bytes: (UInt8, UInt8)) {
        self = unsafeBitCast(bytes, to: UInt16.self)
    }

    var bytes: (UInt8, UInt8) {
        unsafeBitCast(self, to: (UInt8, UInt8).self)
    }
}

internal extension UInt32 {

    init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
        self = unsafeBitCast(bytes, to: UInt32.self)
    }

    var bytes: (UInt8, UInt8, UInt8, UInt8) {
        unsafeBitCast(self, to: (UInt8, UInt8, UInt8, UInt8).self)
    }
}
