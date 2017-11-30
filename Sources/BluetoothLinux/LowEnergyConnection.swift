//
//  LowEnergyConnection.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 11/29/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
    import CSwiftBluetoothLinux
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth

public extension Adapter {
    
    public func lowEnergyCreateConnection(address peerAddress: Address,
                                          type peerAddressType: LowEnergyAddressType = .public,
                                          ownAddressType: LowEnergyAddressType = .public,
                                          commandTimeout timeout: Int = 1000) throws {
        
        let parameters = LowEnergyCommand.CreateConnectionParameter(peerAddressType: peerAddressType,
                                                                    peerAddress: peerAddress,
                                                                    ownAddressType: ownAddressType)
        
        try lowEnergyCreateConnection(parameters: parameters, commandTimeout: timeout)
    }
    
    public func lowEnergyCreateConnection(parameters: LowEnergyCommand.CreateConnectionParameter,
                                          commandTimeout timeout: Int = 1000) throws {
        
        // connect with specified parameters
        try deviceRequest(parameters, timeout: timeout)
    }
    
    public func updateLowEnergyConnection(handle: UInt16) throws {
        
        
    }
}
