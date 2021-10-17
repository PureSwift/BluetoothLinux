//
//  IOCTL.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SystemPackage

/// Bluetooth HCI `ioctl` requests
@frozen
public struct BluetoothIO: Equatable, Hashable, RawRepresentable, IOControlID {
    
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    private init(_ raw: UInt) {
        self.init(rawValue: raw)
    }
}

// TODO: All HCI ioctl defines
public extension BluetoothIO {
    
    // #define HCIDEVUP    _IOW('H', 201, int)
    @_alwaysEmitIntoClient
    static var deviceUp: BluetoothIO            { IOW(H, 201, CInt.self) }
    
    // #define HCIDEVDOWN    _IOW('H', 202, int)
    @_alwaysEmitIntoClient
    static var deviceDown: BluetoothIO          { IOW(H, 202, CInt.self) }
    
    // #define HCIDEVRESET    _IOW('H', 203, int)
    @_alwaysEmitIntoClient
    static var deviceReset: BluetoothIO         { IOW(H, 203, CInt.self) }
    
    // #define HCIDEVRESTAT    _IOW('H', 204, int)
    @_alwaysEmitIntoClient
    static var deviceRestat: BluetoothIO        { IOW(H, 204, CInt.self) }
    
    // #define HCIGETDEVLIST    _IOR('H', 210, int)
    @_alwaysEmitIntoClient
    static var getDeviceList: BluetoothIO       { IOR(H, 210, CInt.self) }
    
    // #define HCIGETDEVINFO    _IOR('H', 211, int)
    @_alwaysEmitIntoClient
    static var getDeviceInfo: BluetoothIO       { IOR(H, 211, CInt.self) }
    
    // #define HCIGETCONNLIST    _IOR('H', 212, int)
    @_alwaysEmitIntoClient
    static var getConnectionList: BluetoothIO   { IOR(H, 212, CInt.self) }
    
    // #define HCIGETCONNINFO    _IOR('H', 213, int)
    @_alwaysEmitIntoClient
    static var getConnectionInfo: BluetoothIO   { IOR(H, 213, CInt.self) }
    
    // #define HCIGETAUTHINFO    _IOR('H', 215, int)
    static var getAuthenticationInfo: BluetoothIO   { IOR(H, 213, CInt.self) }

    //#define HCISETRAW    _IOW('H', 220, int)
    //#define HCISETSCAN    _IOW('H', 221, int)
    //#define HCISETAUTH    _IOW('H', 222, int)
    //#define HCISETENCRYPT    _IOW('H', 223, int)
    //#define HCISETPTYPE    _IOW('H', 224, int)
    //#define HCISETLINKPOL    _IOW('H', 225, int)
    //#define HCISETLINKMODE    _IOW('H', 226, int)
    //#define HCISETACLMTU    _IOW('H', 227, int)
    //#define HCISETSCOMTU    _IOW('H', 228, int)

    //#define HCIBLOCKADDR    _IOW('H', 230, int)
    //#define HCIUNBLOCKADDR    _IOW('H', 231, int)
    
    // #define HCIINQUIRY    _IOR('H', 240, int)
    @_alwaysEmitIntoClient
    static var inquiry: BluetoothIO         { IOR(H, 240, CInt.self) }
}

internal extension BluetoothIO {
    
    @usableFromInline
    static var H: CInt { CInt(UnicodeScalar(unicodeScalarLiteral: "H").value) }
    
    @usableFromInline
    static func IOW<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> BluetoothIO {
        return BluetoothIO(rawValue: _IOW(type, nr, size))
    }
    
    @usableFromInline
    static func IOR<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> BluetoothIO {
        return BluetoothIO(rawValue: _IOR(type, nr, size))
    }
    
    @usableFromInline
    static var NRBITS: CInt       { CInt(8) }
    
    @usableFromInline
    static var TYPEBITS: CInt     { CInt(8) }
    
    @usableFromInline
    static var SIZEBITS: CInt     { CInt(14) }
    
    @usableFromInline
    static var DIRBITS: CInt      { CInt(2) }
    
    @usableFromInline
    static var NRMASK: CInt       { CInt((1 << NRBITS)-1) }
    
    @usableFromInline
    static var TYPEMASK: CInt     { CInt((1 << TYPEBITS)-1) }
    
    @usableFromInline
    static var SIZEMASK: CInt     { CInt((1 << SIZEBITS)-1) }
    
    @usableFromInline
    static var DIRMASK: CInt      { CInt((1 << DIRBITS)-1) }
    
    @usableFromInline
    static var NRSHIFT: CInt      { CInt(0) }
    
    @usableFromInline
    static var TYPESHIFT: CInt    { CInt(NRSHIFT+NRBITS) }
    
    @usableFromInline
    static var SIZESHIFT: CInt    { CInt(TYPESHIFT+TYPEBITS) }
    
    @usableFromInline
    static var DIRSHIFT: CInt     { CInt(SIZESHIFT+SIZEBITS) }
    
    @usableFromInline
    static var NONE: CUnsignedInt         { CUnsignedInt(0) }
    
    @usableFromInline
    static var WRITE: CUnsignedInt        { CUnsignedInt(1) }
    
    @usableFromInline
    static var READ: CUnsignedInt         { CUnsignedInt(2) }
    
    @usableFromInline
    static func _TYPECHECK<T>(_ type: T.Type) -> CInt {
        return CInt(MemoryLayout<T>.size)
    }
    
    /// #define _IOC(dir,type,nr,size) \
    /// (((dir)  << _IOC_DIRSHIFT) | \
    /// ((type) << _IOC_TYPESHIFT) | \
    /// ((nr)   << _IOC_NRSHIFT) | \
    /// ((size) << _IOC_SIZESHIFT))
    @usableFromInline
    static func _IOC(
        _ direction: CUnsignedInt,
        _ type: CInt,
        _ nr: CInt,
        _ size: CInt
    ) -> CUnsignedLong {
        let dir = CInt(direction)
        let dirValue = dir << DIRSHIFT
        let typeValue = type << TYPESHIFT
        let nrValue = nr << NRSHIFT
        let sizeValue = size << SIZESHIFT
        let value = CLong(dirValue | typeValue | nrValue | sizeValue)
        return CUnsignedLong(bitPattern: value)
    }
    
    @usableFromInline
    static func _IOW<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
        return _IOC(WRITE, type, nr, _TYPECHECK(size))
    }
    
    @usableFromInline
    static func _IOR<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
        return _IOC(READ, type, nr, _TYPECHECK(size))
    }
}
