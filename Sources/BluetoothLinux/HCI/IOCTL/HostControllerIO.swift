//
//  HostControllerIO.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Socket

/// Bluetooth HCI `ioctl` requests
@frozen
public struct HostControllerIO: RawRepresentable, Hashable, Codable, IOControlID {
  
    /// The raw C value.
    public let rawValue: UInt
    
    /// Creates a strongly-typed file handle from a raw C value.
    public init?(rawValue: UInt) {
        let value = HostControllerIO(rawValue)
        guard Self._allCases.keys.contains(value)
            else { return nil }
        self = value
    }
    
    @_alwaysEmitIntoClient
    private init(_ raw: UInt) {
        self.rawValue = raw
    }
}

extension HostControllerIO: CaseIterable {
    
    public static var allCases: [HostControllerIO] {
        return [HostControllerIO](_allCases.keys)
    }
}

public extension HostControllerIO {
    
    @_alwaysEmitIntoClient
    static var deviceUp: HostControllerIO               { IOW("H", 201, CInt.self) }

    @_alwaysEmitIntoClient
    static var deviceDown: HostControllerIO             { IOW("H", 202, CInt.self)}

    @_alwaysEmitIntoClient
    static var deviceReset: HostControllerIO            { IOW("H", 203, CInt.self) }

    @_alwaysEmitIntoClient
    static var deviceRestat: HostControllerIO           { IOW("H", 204, CInt.self) }

    @_alwaysEmitIntoClient
    static var getDeviceList: HostControllerIO          { IOR("H", 210, CInt.self) }

    @_alwaysEmitIntoClient
    static var getDeviceInfo: HostControllerIO          { IOR("H", 211, CInt.self) }

    @_alwaysEmitIntoClient
    static var getConnectionList: HostControllerIO      { IOR("H", 212, CInt.self) }

    @_alwaysEmitIntoClient
    static var getConnectionInfo: HostControllerIO      { IOR("H", 213, CInt.self) }

    @_alwaysEmitIntoClient
    static var getAuthenticationInfo: HostControllerIO  { IOR("H", 215, CInt.self) }

    @_alwaysEmitIntoClient
    static var setRaw: HostControllerIO                 { IOW("H", 220, CInt.self) }

    @_alwaysEmitIntoClient
    static var setScan: HostControllerIO                { IOW("H", 221, CInt.self) }

    @_alwaysEmitIntoClient
    static var setAuthentication: HostControllerIO      { IOW("H", 222, CInt.self) }

    @_alwaysEmitIntoClient
    static var setEncrypt: HostControllerIO             { IOW("H", 223, CInt.self) }

    @_alwaysEmitIntoClient
    static var setPacketType: HostControllerIO          { IOW("H", 224, CInt.self) }

    @_alwaysEmitIntoClient
    static var setLinkPolicy: HostControllerIO          { IOW("H", 225, CInt.self) }

    @_alwaysEmitIntoClient
    static var setLinkMode: HostControllerIO            { IOW("H", 226, CInt.self) }

    @_alwaysEmitIntoClient
    static var setACLMTU: HostControllerIO              { IOW("H", 227, CInt.self) }

    @_alwaysEmitIntoClient
    static var setSCOMTU: HostControllerIO              { IOW("H", 228, CInt.self) }

    @_alwaysEmitIntoClient
    static var blockAddress: HostControllerIO           { IOW("H", 230, CInt.self) }

    @_alwaysEmitIntoClient
    static var unblockAddress: HostControllerIO         { IOW("H", 231, CInt.self) }

    @_alwaysEmitIntoClient
    static var inquiry: HostControllerIO                { IOR("H", 240, CInt.self) }
}

extension HostControllerIO: CustomStringConvertible, CustomDebugStringConvertible {
    
    @_alwaysEmitIntoClient
    internal static var _allCases: [HostControllerIO: String] {
        return [
            .deviceUp:                  ".deviceUp",
            .deviceDown:                ".deviceDown",
            .deviceReset:               ".deviceReset",
            .deviceRestat:              ".deviceRestat",
            .getDeviceList:             ".getDeviceList",
            .getDeviceInfo:             ".getDeviceInfo",
            .getConnectionList:         ".getConnectionList",
            .getConnectionInfo:         ".getConnectionInfo",
            .getAuthenticationInfo:     ".getAuthenticationInfo",
            .setRaw:                    ".setRaw",
            .setScan:                   ".setScan",
            .setAuthentication:         ".setAuthentication",
            .setEncrypt:                ".setEncrypt",
            .setPacketType:             ".setPacketType",
            .setLinkPolicy:             ".setLinkPolicy",
            .setLinkMode:               ".setLinkMode",
            .setACLMTU:                 ".setACLMTU",
            .setSCOMTU:                 ".setSCOMTU",
            .blockAddress:              ".blockAddress",
            .unblockAddress:            ".unblockAddress",
            .inquiry:                   ".inquiry",
        ]
    }
    
    public var description: String {
        return Self._allCases[self] ?? rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}

internal extension HostControllerIO {
    
    @_alwaysEmitIntoClient
    static func IOW<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> HostControllerIO {
        return HostControllerIO(_IOW(type, nr, size))
    }
    
    @_alwaysEmitIntoClient
    static func IOR<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> HostControllerIO {
        return HostControllerIO(_IOR(type, nr, size))
    }
}
