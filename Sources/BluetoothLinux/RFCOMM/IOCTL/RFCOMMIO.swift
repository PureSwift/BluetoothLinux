//
//  RFCOMMIO.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import SystemPackage

public enum RFCOMMIO: Hashable, CaseIterable, IOControlID {
    
    case createDevice
    case releaseDevice
    case getDeviceList
    case getDeviceInfo
    
    public init?(rawValue: UInt) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    public var rawValue: UInt {
        switch self {
        case .createDevice:             return _RFCOMMCREATEDEV
        case .releaseDevice:            return _RFCOMMRELEASEDEV
        case .getDeviceList:            return _RFCOMMGETDEVLIST
        case .getDeviceInfo:            return _RFCOMMGETDEVINFO
        }
    }
}

@_alwaysEmitIntoClient
internal var _RFCOMMCREATEDEV: CUnsignedLong     { _IOW("R", 200, CInt.self) }

@_alwaysEmitIntoClient
internal var _RFCOMMRELEASEDEV: CUnsignedLong    { _IOW("R", 201, CInt.self) }

@_alwaysEmitIntoClient
internal var _RFCOMMGETDEVLIST: CUnsignedLong    { _IOR("R", 210, CInt.self) }

@_alwaysEmitIntoClient
internal var _RFCOMMGETDEVINFO: CUnsignedLong    { _IOR("R", 211, CInt.self) }
