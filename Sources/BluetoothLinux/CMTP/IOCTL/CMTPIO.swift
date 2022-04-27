//
//  CMTPIO.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import SystemPackage
import Socket

/// Bluetooth CMTP `ioctl` requests
@frozen
public enum CMTPIO: Hashable, CaseIterable, IOControlID {
    
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
        case .addConnection:            return _CMTPCONNADD
        case .removeConnection:         return _CMTPCONNDEL
        case .getConnectionList:        return _CMTPGETCONNLIST
        case .getConnectionInfo:        return _CMTPGETCONNINFO
        }
    }
}

@_alwaysEmitIntoClient
internal var _CMTPCONNADD: CUnsignedLong        { _IOW("C", 200, CInt.self) }
@_alwaysEmitIntoClient
internal var _CMTPCONNDEL: CUnsignedLong         { _IOW("C", 201, CInt.self) }
@_alwaysEmitIntoClient
internal var _CMTPGETCONNLIST: CUnsignedLong     { _IOR("C", 210, CInt.self) }
@_alwaysEmitIntoClient
internal var _CMTPGETCONNINFO: CUnsignedLong     { _IOR("C", 211, CInt.self) }
