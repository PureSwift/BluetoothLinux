//
//  BluetoothProtocol.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SystemPackage
import Socket

/// Bluetooth Socket Protocol
public enum BluetoothSocketProtocol: Int32, Codable {
    
    /// Bluetooth L2CAP (Logical link control and adaptation protocol)
    case l2cap      = 0
    
    /// Bluetooth HCI protocol (Host Controller Interface)
    case hci        = 1
    
    /// Bluetooth SCO protocol (Synchronous Connection Oriented Link)
    case sco        = 2
    
    /// Bluetooth RFCOMM protocol (Radio frequency communication)
    case rfcomm     = 3
    
    /// Bluetooth BNEP (network encapsulation protocol)
    case bnep       = 4
    
    /// CAPI Message Transport Protocol
    case cmtp       = 5
    
    /// HIDP (Human Interface Device Protocol) is a transport layer for HID reports.
    case hidp       = 6
    
    /// Audio/video data transport protocol
    case avdtp      = 7
}

extension BluetoothSocketProtocol: SocketProtocol {
        
    @_alwaysEmitIntoClient
    public static var family: SocketAddressFamily { .bluetooth }
    
    @_alwaysEmitIntoClient
    public var type: SocketType {
        switch self {
        case .l2cap:    return .sequencedPacket
        case .hci:      return .raw
        case .sco:      return .sequencedPacket
        case .rfcomm:   return .stream
        case .bnep:     return .raw
        case .cmtp:     return .raw
        case .hidp:     return .raw
        case .avdtp:    return .raw
        }
    }
}
