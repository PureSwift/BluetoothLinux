//
//  RFCOMMDevice.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage

/// RFCOMM Device Information
@frozen
public struct RFCOMMDevice: Equatable, Hashable {
    
    public let id: HostController.ID
    
    public var flags: BitMaskOptionSet<RFCOMMFlag>
    
    public var state: RFCOMMState
    
    public var source: BluetoothAddress
    
    public var destination: BluetoothAddress
    
    public var channel: UInt8
}

extension RFCOMMDevice: Identifiable { }

internal extension RFCOMMDevice {
    
    @usableFromInline
    init(_ cValue: CInterop.RFCOMMDeviceInformation) {
        self.id = .init(rawValue: cValue.id)
        self.flags = .init(rawValue: cValue.flags)
        self.state = .init(rawValue: cValue.state) ?? .unknown
        self.source = cValue.source
        self.destination = cValue.source
        self.channel = cValue.channel
    }
}
