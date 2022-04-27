//
//  SocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import Socket

/// Bluetooth Socket Options
public enum BluetoothSocketOption: CInt, SocketOptionID {
    
    @_alwaysEmitIntoClient
    public static var optionLevel: SocketOptionLevel { .bluetooth }
    
    /// Bluetooth Security socket option
    case security       = 4 // BT_SECURITY

    /// Bluetooth defer setup socket option
    case deferSetup     = 7 // BT_DEFER_SETUP
    
    /// Bluetooth flushable socket option
    case flushable      = 8
    
    /// Bluetooth power socket option
    case power          = 9
    
    /// Bluetooth Channel Policy socket option
    case channelPolicy  = 10 // BT_CHANNEL_POLICY
    
    /// Bluetooth Voice options
    case voice          = 11 // BT_VOICE
    
    /// Bluetooth Socket Send MTU
    case sendMTU        = 12 // BT_SNDMTU
    
    /// Bluetooth Socket Recieve MTU
    case recieveMTU     = 13 // BT_RCVMTU
    
    /// Bluetooth Phy
    case phy            = 14 // BT_PHY
    
    /// Bluetooth Mode
    case mode           = 15 // BT_MODE
    
    /// Bluetooth Packet Status
    case packetStatus   = 16 // BT_PKT_STATUS
}
