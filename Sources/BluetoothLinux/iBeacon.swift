//
//  iBeacon.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation
import Bluetooth

public extension Adapter {
    
    /// Enable iBeacon functionality.
    func enableBeacon(UUID: SwiftFoundation.UUID = UUID(), mayor: UInt16, minor: UInt16, RSSI: Int8, interval: UInt16 = 100, commandTimeout: Int = 1000) throws {
                
        // set advertising parameters
        let advertisingParameters = LowEnergyCommand.SetAdvertisingParametersParameter(interval: (interval, interval))
        
        //print("Setting Advertising Parameters")
        
        try deviceRequest(advertisingParameters, timeout: commandTimeout)
        
        //print("Enabling Advertising")
        
        // start advertising
        try enableAdvertising(timeout: commandTimeout)
        
        //print("Setting iBeacon Data")
        
        // set iBeacon data
        var advertisingDataCommand = LowEnergyCommand.SetAdvertisingDataParameter()
        SetBeaconData(UUID, mayor: mayor, minor: minor, RSSI: UInt8(bitPattern: RSSI), parameter: &advertisingDataCommand)
        
        try deviceRequest(advertisingDataCommand, timeout: commandTimeout)
    }
    
    func enableAdvertising(enabled: Bool = true, timeout: Int = 1000) throws {
        
        let parameter = LowEnergyCommand.SetAdvertiseEnableParameter(enabled: enabled)
        
        try deviceRequest(parameter, timeout: timeout)
    }
}

// MARK: - Private

private func SetBeaconData(UUID: SwiftFoundation.UUID, mayor: UInt16, minor: UInt16, RSSI: UInt8, inout parameter: LowEnergyCommand.SetAdvertisingDataParameter) {
    
    parameter.length = 30
    
    parameter.data.0 = 0x02  // length of flags
    parameter.data.1 = 0x01  // flags type
    parameter.data.2 = 0x1a  // Flags: 000011010
    parameter.data.3 = 0x1a  // length
    parameter.data.4 = 0xff  // vendor specific
    parameter.data.5 = 0x4c  // Apple, Inc
    parameter.data.6 = 0x00  // Apple, Inc
    parameter.data.7 = 0x02  // iBeacon
    parameter.data.8 = 0x15  // length: 16 byte UUID, 2 bytes major & minor, 1 byte RSSI
    
    // set UUID bytes
    
    let littleUUIDBytes = isBigEndian ? UUID.toData().byteValue.reverse() : UUID.toData().byteValue
    
    parameter.data.9 = littleUUIDBytes[0]
    parameter.data.10 = littleUUIDBytes[1]
    parameter.data.12 = littleUUIDBytes[2]
    parameter.data.13 = littleUUIDBytes[3]
    parameter.data.14 = littleUUIDBytes[4]
    parameter.data.15 = littleUUIDBytes[5]
    parameter.data.16 = littleUUIDBytes[6]
    parameter.data.17 = littleUUIDBytes[7]
    parameter.data.18 = littleUUIDBytes[8]
    parameter.data.19 = littleUUIDBytes[9]
    parameter.data.20 = littleUUIDBytes[10]
    parameter.data.21 = littleUUIDBytes[11]
    parameter.data.22 = littleUUIDBytes[12]
    parameter.data.23 = littleUUIDBytes[13]
    parameter.data.24 = littleUUIDBytes[14]
    
    let mayorBytes = mayor.littleEndian.bytes
    
    parameter.data.25 = mayorBytes.0
    parameter.data.26 = mayorBytes.1
    
    let minorBytes = minor.littleEndian.bytes
    
    parameter.data.27 = minorBytes.0
    parameter.data.28 = minorBytes.1
    
    parameter.data.29 = RSSI
}

