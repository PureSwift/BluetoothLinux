//
//  BNEPIO.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import SystemPackage
import Socket

/// Bluetooth BNEP `ioctl` requests
@frozen
public enum BNEPIO: Hashable, CaseIterable, IOControlID {
    
    case addConnection
    case removeConnection
    case getConnectionList
    case getConnectionInfo
    case getSupportedFeatures
    
    public init?(rawValue: UInt) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    public var rawValue: UInt {
        switch self {
        case .addConnection:            return _BNEPCONNADD
        case .removeConnection:         return _BNEPCONNDEL
        case .getConnectionList:        return _BNEPGETCONNLIST
        case .getConnectionInfo:        return _BNEPGETCONNINFO
        case .getSupportedFeatures:     return _BNEPGETSUPPFEAT
        }
    }
}

@_alwaysEmitIntoClient
var _BNEPCONNADD: CUnsignedLong         { _IOW("B", 200, CInt.self) }
    
@_alwaysEmitIntoClient
var _BNEPCONNDEL: CUnsignedLong         { _IOW("B", 201, CInt.self) }
    
@_alwaysEmitIntoClient
var _BNEPGETCONNLIST: CUnsignedLong     { _IOR("B", 210, CInt.self) }
    
@_alwaysEmitIntoClient
var _BNEPGETCONNINFO: CUnsignedLong     { _IOR("B", 211, CInt.self) }
    
@_alwaysEmitIntoClient
var _BNEPGETSUPPFEAT: CUnsignedLong     { _IOR("B", 212, CInt.self) }
