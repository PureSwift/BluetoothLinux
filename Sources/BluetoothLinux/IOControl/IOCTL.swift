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
public enum HostControllerIO: Equatable, Hashable, RawRepresentable, IOControlID, CaseIterable {
    
    case deviceUp
    case deviceDown
    case deviceReset
    case deviceRestat
    case getDeviceList
    case getDeviceInfo
    case getConnectionList
    case getConnectionInfo
    case getAuthenticationInfo
    case setRaw
    case setScan
    case setAuthentication
    case setEncrypt
    case setPacketType
    case setLinkPolicy
    case setLinkMode
    case setACLMTU
    case setSCOMTU
    case blockAddress
    case unblockAddress
    case inquiry
    
    public init?(rawValue: UInt) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    @inline(never)
    public var rawValue: UInt {
        switch self {
        case .deviceUp:                 return HostControllerIO.HCIDEVUP
        case .deviceDown:               return HostControllerIO.HCIDEVDOWN
        case .deviceReset:              return HostControllerIO.HCIDEVRESET
        case .deviceRestat:             return HostControllerIO.HCIDEVRESTAT
        case .getDeviceList:            return HostControllerIO.HCIGETDEVLIST
        case .getDeviceInfo:            return HostControllerIO.HCIGETDEVINFO
        case .getConnectionList:        return HostControllerIO.HCIGETCONNLIST
        case .getConnectionInfo:        return HostControllerIO.HCIGETCONNINFO
        case .getAuthenticationInfo:    return HostControllerIO.HCIGETAUTHINFO
        case .setRaw:                   return HostControllerIO.HCISETRAW
        case .setScan:                  return HostControllerIO.HCISETSCAN
        case .setAuthentication:        return HostControllerIO.HCISETAUTH
        case .setEncrypt:               return HostControllerIO.HCISETENCRYPT
        case .setPacketType:            return HostControllerIO.HCISETPTYPE
        case .setLinkPolicy:            return HostControllerIO.HCISETLINKPOL
        case .setLinkMode:              return HostControllerIO.HCISETLINKMODE
        case .setACLMTU:                return HostControllerIO.HCISETACLMTU
        case .setSCOMTU:                return HostControllerIO.HCISETSCOMTU
        case .blockAddress:             return HostControllerIO.HCIBLOCKADDR
        case .unblockAddress:           return HostControllerIO.HCIUNBLOCKADDR
        case .inquiry:                  return HostControllerIO.HCIINQUIRY
        }
    }
}

/* HCI ioctl defines */

internal extension HostControllerIO {
    
    static var HCIDEVUP: CUnsignedLong          { _IOW(H, 201, CInt.self) }
    
    static var HCIDEVDOWN: CUnsignedLong        { _IOW(H, 202, CInt.self) }
    static var HCIDEVRESET: CUnsignedLong       { _IOW(H, 203, CInt.self) }
    static var HCIDEVRESTAT: CUnsignedLong      { _IOW(H, 204, CInt.self) }

    static var HCIGETDEVLIST: CUnsignedLong     { _IOR(H, 210, CInt.self) }
    static var HCIGETDEVINFO: CUnsignedLong     { _IOR(H, 211, CInt.self) }
    static var HCIGETCONNLIST: CUnsignedLong    { _IOR(H, 212, CInt.self) }
    static var HCIGETCONNINFO: CUnsignedLong    { _IOR(H, 213, CInt.self) }
    static var HCIGETAUTHINFO: CUnsignedLong    { _IOR(H, 215, CInt.self) }

    static var HCISETRAW: CUnsignedLong         { _IOW(H, 220, CInt.self) }
    static var HCISETSCAN: CUnsignedLong        { _IOW(H, 221, CInt.self) }
    static var HCISETAUTH: CUnsignedLong        { _IOW(H, 222, CInt.self) }
    static var HCISETENCRYPT: CUnsignedLong     { _IOW(H, 223, CInt.self) }
    static var HCISETPTYPE: CUnsignedLong       { _IOW(H, 224, CInt.self) }
    static var HCISETLINKPOL: CUnsignedLong     { _IOW(H, 225, CInt.self) }
    static var HCISETLINKMODE: CUnsignedLong    { _IOW(H, 226, CInt.self) }
    static var HCISETACLMTU: CUnsignedLong      { _IOW(H, 227, CInt.self) }
    static var HCISETSCOMTU: CUnsignedLong      { _IOW(H, 228, CInt.self) }

    static var HCIBLOCKADDR: CUnsignedLong      { _IOW(H, 230, CInt.self) }
    static var HCIUNBLOCKADDR: CUnsignedLong    { _IOW(H, 231, CInt.self) }
    
    static var HCIINQUIRY: CUnsignedLong        { _IOR(H, 240, CInt.self) }
}

internal extension HostControllerIO {
    
    @usableFromInline
    static var H: CInt { CInt(UnicodeScalar(unicodeScalarLiteral: "H").value) }
    
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
