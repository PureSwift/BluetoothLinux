//
//  HostControllerIO.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
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
        case .deviceUp:                 return _HCIDEVUP
        case .deviceDown:               return _HCIDEVDOWN
        case .deviceReset:              return _HCIDEVRESET
        case .deviceRestat:             return _HCIDEVRESTAT
        case .getDeviceList:            return _HCIGETDEVLIST
        case .getDeviceInfo:            return _HCIGETDEVINFO
        case .getConnectionList:        return _HCIGETCONNLIST
        case .getConnectionInfo:        return _HCIGETCONNINFO
        case .getAuthenticationInfo:    return _HCIGETAUTHINFO
        case .setRaw:                   return _HCISETRAW
        case .setScan:                  return _HCISETSCAN
        case .setAuthentication:        return _HCISETAUTH
        case .setEncrypt:               return _HCISETENCRYPT
        case .setPacketType:            return _HCISETPTYPE
        case .setLinkPolicy:            return _HCISETLINKPOL
        case .setLinkMode:              return _HCISETLINKMODE
        case .setACLMTU:                return _HCISETACLMTU
        case .setSCOMTU:                return _HCISETSCOMTU
        case .blockAddress:             return _HCIBLOCKADDR
        case .unblockAddress:           return _HCIUNBLOCKADDR
        case .inquiry:                  return _HCIINQUIRY
        }
    }
}

var _HCIDEVUP: CUnsignedLong          { _IOW("H", 201, CInt.self) }

var _HCIDEVDOWN: CUnsignedLong        { _IOW("H", 202, CInt.self) }
var _HCIDEVRESET: CUnsignedLong       { _IOW("H", 203, CInt.self) }
var _HCIDEVRESTAT: CUnsignedLong      { _IOW("H", 204, CInt.self) }

var _HCIGETDEVLIST: CUnsignedLong     { _IOR("H", 210, CInt.self) }
var _HCIGETDEVINFO: CUnsignedLong     { _IOR("H", 211, CInt.self) }
var _HCIGETCONNLIST: CUnsignedLong    { _IOR("H", 212, CInt.self) }
var _HCIGETCONNINFO: CUnsignedLong    { _IOR("H", 213, CInt.self) }
var _HCIGETAUTHINFO: CUnsignedLong    { _IOR("H", 215, CInt.self) }

var _HCISETRAW: CUnsignedLong         { _IOW("H", 220, CInt.self) }
var _HCISETSCAN: CUnsignedLong        { _IOW("H", 221, CInt.self) }
var _HCISETAUTH: CUnsignedLong        { _IOW("H", 222, CInt.self) }
var _HCISETENCRYPT: CUnsignedLong     { _IOW("H", 223, CInt.self) }
var _HCISETPTYPE: CUnsignedLong       { _IOW("H", 224, CInt.self) }
var _HCISETLINKPOL: CUnsignedLong     { _IOW("H", 225, CInt.self) }
var _HCISETLINKMODE: CUnsignedLong    { _IOW("H", 226, CInt.self) }
var _HCISETACLMTU: CUnsignedLong      { _IOW("H", 227, CInt.self) }
var _HCISETSCOMTU: CUnsignedLong      { _IOW("H", 228, CInt.self) }

var _HCIBLOCKADDR: CUnsignedLong      { _IOW("H", 230, CInt.self) }
var _HCIUNBLOCKADDR: CUnsignedLong    { _IOW("H", 231, CInt.self) }

var _HCIINQUIRY: CUnsignedLong        { _IOR("H", 240, CInt.self) }
