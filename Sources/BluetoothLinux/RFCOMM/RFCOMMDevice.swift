//
//  RFCOMMDevice.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage

public struct RFCOMMDevice: Equatable, Hashable {
    
    public let id: HostController.ID
    
    public var flags: BitMaskOptionSet<RFCOMMFlag>
    
    public var state: RFCOMMState
    
    public var source: BluetoothAddress
    
    public var destination: BluetoothAddress
    
    public var channel: UInt8
}

extension RFCOMMDevice: Identifiable { }
