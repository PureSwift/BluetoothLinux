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

/// 31 Byte Advertising Data
public typealias LowEnergyAdvertisingData = (Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte)

public extension Adapter {
    
    /// Enable iBeacon functionality.
    func enableBeacon(UUID: SwiftFoundation.UUID = UUID(), mayor: UInt16, minor: UInt16, RSSI: Int8, interval: Int = 100, commandTimeout: Int = 1000) throws {
        
        assert(interval <= Int(UInt16.max), "interval > UInt16.max")
        
        // set advertising parameters
        var advertisingParameters = le_set_advertising_parameters_cp()
        memset(&advertisingParameters, 0, sizeof(le_set_advertising_parameters_cp))
        
        advertisingParameters.max_interval = UInt16(interval).littleEndian
        advertisingParameters.min_interval = UInt16(interval).littleEndian
        //advertisingParameters.advtype = 3  // advertising non-connectable
        advertisingParameters.chan_map = 7 // // all three advertising channels
        
        try self.deviceRequest(LowEnergyCommand.SetAdvertisingParameters, parameter: advertisingParameters, timeout: commandTimeout)
        
        // start advertising
        var enableAdvertise = le_set_advertise_enable_cp()
        memset(&enableAdvertise, 0, sizeof(le_set_advertise_enable_cp.self))
        
        enableAdvertise.enable = 0x01 // true
        
        try self.deviceRequest(LowEnergyCommand.SetAdvertiseEnable, parameter: enableAdvertise, timeout: commandTimeout)
        
        // set iBeacon data
        var advertisingDataCommand = le_set_advertising_data_cp()
        memset(&advertisingDataCommand, 0, sizeof(le_set_advertising_data_cp))
        
        let beaconData = GenerateBeaconData(UUID, mayor: mayor, minor: minor, RSSI: RSSI)
        advertisingDataCommand.length = beaconData.length
        advertisingDataCommand.data = beaconData.data
        
        try self.deviceRequest(LowEnergyCommand.SetAdvertisingData, parameter: advertisingDataCommand, timeout: commandTimeout)
    }
    
    func setAdvertising(enabled: Bool) throws {
        
        // stop advertising
        var enableAdvertise = le_set_advertise_enable_cp()
        enableAdvertise.enable = 0x00 // false
        
        try self.deviceRequest(LowEnergyCommand.SetAdvertiseEnable, parameter: enableAdvertise)
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
    parameter.data.9 = UUID.byteValue.0
    parameter.data.10 = UUID.byteValue.1
    parameter.data.12 = UUID.byteValue.2
    parameter.data.13 = UUID.byteValue.3
    parameter.data.14 = UUID.byteValue.4
    parameter.data.15 = UUID.byteValue.5
    parameter.data.16 = UUID.byteValue.6
    parameter.data.17 = UUID.byteValue.7
    parameter.data.18 = UUID.byteValue.8
    parameter.data.19 = UUID.byteValue.9
    parameter.data.20 = UUID.byteValue.10
    parameter.data.21 = UUID.byteValue.11
    parameter.data.22 = UUID.byteValue.12
    parameter.data.23 = UUID.byteValue.13
    parameter.data.24 = UUID.byteValue.14
    
    let mayorBytes = mayor.littleEndianBytes
    
    parameter.data.25 = mayorBytes.0
    parameter.data.26 = mayorBytes.1
    
    let minorBytes = minor.littleEndianBytes
    
    parameter.data.27 = minorBytes.0
    parameter.data.28 = minorBytes.1
    
    parameter.data.29 = RSSI
}

