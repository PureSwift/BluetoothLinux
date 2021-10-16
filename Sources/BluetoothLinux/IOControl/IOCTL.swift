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
    static var deviceUp: BluetoothIO        { IOW(H, 201, CInt.self) }
    
    // #define HCIDEVDOWN    _IOW('H', 202, int)
    static var deviceDown: BluetoothIO      { IOW(H, 202, CInt.self) }
    
    // #define HCIDEVRESET    _IOW('H', 203, int)
    static var deviceReset: BluetoothIO     { IOW(H, 203, CInt.self) }
    
    // #define HCIDEVRESTAT    _IOW('H', 204, int)
    static var deviceRestat: BluetoothIO    { IOW(H, 204, CInt.self) }
    
    // #define HCIGETDEVLIST    _IOR('H', 210, int)
    static var getDeviceList: BluetoothIO   { IOR(H, 210, CInt.self) }
    
    // #define HCIGETDEVINFO    _IOR('H', 211, int)
    static var getDeviceInfo: BluetoothIO   { IOR(H, 211, CInt.self) }
    
    // #define HCIINQUIRY    _IOR('H', 240, int)
    static var inquiry: BluetoothIO         { IOR(H, 240, CInt.self) }
}

private extension BluetoothIO {
    
    @_alwaysEmitIntoClient
    static var H: CInt { CInt(UnicodeScalar(unicodeScalarLiteral: "H").value) }
    
    @usableFromInline
    static func IOW<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> BluetoothIO {
        return BluetoothIO(rawValue: _IOW(type, nr, size))
    }
    
    @usableFromInline
    static func IOR<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> BluetoothIO {
        return BluetoothIO(rawValue: _IOR(type, nr, size))
    }
    
    static var NRBITS: CInt       { CInt(8) }
    
    static var TYPEBITS: CInt     { CInt(8) }
    
    static var SIZEBITS: CInt     { CInt(14) }
    
    static var DIRBITS: CInt      { CInt(2) }
    
    static var NRMASK: CInt       { CInt((1 << NRBITS)-1) }
    
    static var TYPEMASK: CInt     { CInt((1 << TYPEBITS)-1) }
    
    static var SIZEMASK: CInt     { CInt((1 << SIZEBITS)-1) }
    
    static var DIRMASK: CInt      { CInt((1 << DIRBITS)-1) }
    
    static var NRSHIFT: CInt      { CInt(0) }
    
    static var TYPESHIFT: CInt    { CInt(NRSHIFT+NRBITS) }
    
    static var SIZESHIFT: CInt    { CInt(TYPESHIFT+TYPEBITS) }
    
    static var DIRSHIFT: CInt     { CInt(SIZESHIFT+SIZEBITS) }
    
    static var NONE: CUnsignedInt         { CUnsignedInt(0) }
    
    static var WRITE: CUnsignedInt        { CUnsignedInt(1) }
    
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
