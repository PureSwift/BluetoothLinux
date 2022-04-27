//
//  HIDPIO.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import SystemPackage
import Socket

/// Bluetooth HIDP `ioctl` requests
@frozen
public enum HIDPIO: Hashable, CaseIterable, IOControlID {
    
    case addConnection
    case removeConnection
    case getConnectionList
    case getConnectionInfo
    
    public init?(rawValue: UInt) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    public var rawValue: UInt {
        switch self {
        case .addConnection:            return _HIDPCONNADD
        case .removeConnection:         return _HIDPCONNDEL
        case .getConnectionList:        return _HIDPGETCONNLIST
        case .getConnectionInfo:        return _HIDPGETCONNINFO
        }
    }
}

@_alwaysEmitIntoClient
internal var _HIDPCONNADD: CUnsignedLong        { _IOW("H", 200, CInt.self) }

@_alwaysEmitIntoClient
internal var _HIDPCONNDEL: CUnsignedLong        { _IOW("H", 201, CInt.self) }

@_alwaysEmitIntoClient
internal var _HIDPGETCONNLIST: CUnsignedLong    { _IOR("H", 210, CInt.self) }

@_alwaysEmitIntoClient
internal var _HIDPGETCONNINFO: CUnsignedLong    { _IOR("H", 211, CInt.self) }
