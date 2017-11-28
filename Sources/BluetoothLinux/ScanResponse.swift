//
//  ScanResponse.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 11/27/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
    import CSwiftBluetoothLinux
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth

public extension Adapter {
    
    /// Set the LE Scan Response
    func setLowEnergyScanResponse(_ data: LowEnergyScanData, length: UInt8, commandTimeout: Int = 1000) throws {
        
        precondition(length <= 31, "LE Scan Response Data can only be 31 octets")
        
        // set scan response parameters
        let setScanResponseDataCommand = LowEnergyCommand.SetScanResponseDataParameter(data: data, length: length)
        
        //print("Setting Scan Response Data")
        
        try deviceRequest(setScanResponseDataCommand, timeout: commandTimeout)
    }
}
