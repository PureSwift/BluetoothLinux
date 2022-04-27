//
//  SocketOptionLevel.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Socket

internal extension SocketOptionLevel {
    
    /// Bluetooth HCI Socket Option Level
    @_alwaysEmitIntoClient
    static var hostControllerInterface: SocketOptionLevel { SocketOptionLevel(rawValue: 0) }
    
    /// Bluetooth L2CAP Socket Option Level
    @_alwaysEmitIntoClient
    static var l2cap: SocketOptionLevel { SocketOptionLevel(rawValue: 6) }
    
    /// Bluetooth SCO Socket Option Level
    @_alwaysEmitIntoClient
    static var sco: SocketOptionLevel { SocketOptionLevel(rawValue: 17) }
    
    /// Bluetooth RFCOMM Socket Option Level
    @_alwaysEmitIntoClient
    static var rfcomm: SocketOptionLevel { SocketOptionLevel(rawValue: 18) }
}
