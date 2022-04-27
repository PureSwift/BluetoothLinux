//
//  RFCOMMIO.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import SystemPackage
import Socket

/// Bluetooth RFCOMM  `ioctl` requests
@frozen
public struct RFCOMMIO: RawRepresentable, Hashable, Codable, IOControlID {
  
    /// The raw C value.
    public let rawValue: UInt
    
    /// Creates a strongly-typed file handle from a raw C value.
    public init?(rawValue: UInt) {
        let value = RFCOMMIO(rawValue)
        guard Self._allCases.keys.contains(value)
            else { return nil }
        self = value
    }
    
    @_alwaysEmitIntoClient
    private init(_ raw: UInt) {
        self.rawValue = raw
    }
}

extension RFCOMMIO: CaseIterable {
    
    public static var allCases: [RFCOMMIO] {
        return [RFCOMMIO](_allCases.keys)
    }
}

public extension RFCOMMIO {
    
    @_alwaysEmitIntoClient
    static var createDevice: RFCOMMIO   { IOW("R", 200, CInt.self) }
    
    @_alwaysEmitIntoClient
    static var releaseDevice: RFCOMMIO  { IOW("R", 201, CInt.self) }
    
    @_alwaysEmitIntoClient
    static var getDeviceList: RFCOMMIO  { IOR("R", 210, CInt.self) }
    
    @_alwaysEmitIntoClient
    static var getDeviceInfo: RFCOMMIO  { IOR("R", 211, CInt.self) }
}

extension RFCOMMIO: CustomStringConvertible, CustomDebugStringConvertible {
    
    @_alwaysEmitIntoClient
    internal static var _allCases: [RFCOMMIO: String] {
        return [
            .createDevice:  ".createDevice",
            .releaseDevice: ".releaseDevice",
            .getDeviceList: ".getDeviceList",
            .getDeviceInfo: ".getDeviceInfo"
        ]
    }
    
    public var description: String {
        return Self._allCases[self] ?? rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}

internal extension RFCOMMIO {
    
    @_alwaysEmitIntoClient
    static func IOW<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> RFCOMMIO {
        return RFCOMMIO(_IOW(type, nr, size))
    }
    
    @_alwaysEmitIntoClient
    static func IOR<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> RFCOMMIO {
        return RFCOMMIO(_IOR(type, nr, size))
    }
}
