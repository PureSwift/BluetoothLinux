//
//  L2CAPSocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage

/// Bluetooth L2CAP Socket
@frozen
public struct L2CAPSocketAddress {
    
    public typealias ProtocolID = BluetoothSocketProtocol
    
    public static var protocolID: ProtocolID { .l2cap }
    
    // MARK: - Properties
    
    /// HCI device identifier
    public var device: HostController.ID
    
    /// Channel identifier
    public var channel: HCIChannel
    
    // MARK: - Initialization
    
    /// Initialize with device and channel identifiers.
    public init(
        device: HostController.ID = .none,
        channel: HCIChannel = .raw
    ) {
        self.device = device
        self.channel = channel
    }
}
