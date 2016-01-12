//
//  iBeacon.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public extension Bluetooth {
    
    /// 31 Byte String
    public typealias LowEnergyAdvertisingData = (Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte)
}

public extension BluetoothAdapter {
    
    /// Enable iBeacon functionality.
    func enableBeacon(UUID: SwiftFoundation.UUID = UUID(), mayor: UInt16, minor: UInt16, RSSI: Byte, interval: Int = 100, commandTimeout: Int = 1000) throws {
        
        assert(interval <= Int(UInt16.max), "Interval can only be 2 bytes long")
        
        // set advertising parameters
        var advertisingParameters = le_set_advertising_parameters_cp()
        memset(&advertisingParameters, 0, sizeof(le_set_advertising_parameters_cp))
        
        advertisingParameters.max_interval = UInt16(interval).littleEndian
        advertisingParameters.min_interval = UInt16(interval).littleEndian
        advertisingParameters.advtype = 3  // advertising non-connectable
        advertisingParameters.chan_map = 7 // // all three advertising channels
        
        try self.deviceRequest(advertisingParameters, timeout: commandTimeout)
        
        // start advertising
        var enableAdvertise = le_set_advertise_enable_cp()
        memset(&enableAdvertise, 0, sizeof(le_set_advertise_enable_cp.self))
        
        enableAdvertise.enable = 0x01 // true
        
        try self.deviceRequest(enableAdvertise, timeout: commandTimeout)
        
        // set iBeacon data
        var advertisingDataCommand = le_set_advertising_data_cp()
        memset(&advertisingDataCommand, 0, sizeof(le_set_advertising_data_cp))
        
        let beaconData = GenerateBeaconData(UUID, mayor: mayor, minor: minor, RSSI: RSSI)
        advertisingDataCommand.length = beaconData.length
        advertisingDataCommand.data = beaconData.data
        
        try self.deviceRequest(advertisingDataCommand, timeout: commandTimeout)
    }
    
    func disableBeacon() throws {
        
        // stop advertising
        var enableAdvertise = le_set_advertise_enable_cp()
        enableAdvertise.enable = 0x00 // false
        
        try self.deviceRequest(enableAdvertise)
    }
}

// MARK: - Private

private func GenerateBeaconData(UUID: SwiftFoundation.UUID, mayor: UInt16, minor: UInt16, RSSI: Byte) -> (data: Bluetooth.LowEnergyAdvertisingData, length: Byte) {
    
    let length = 30
    
    var data: [UInt8] = [UInt8](count: length, repeatedValue: 0)
    
    data[0] = 0x02  // length of flags
    data[1] = 0x01  // flags type
    data[2] = 0x1a  // Flags: 000011010
    data[3] = 0x1a  // length
    data[4] = 0xff  // vendor specific
    data[5] = 0x4c  // Apple, Inc
    data[6] = 0x00  // Apple, Inc
    data[7] = 0x02  // iBeacon
    data[8] = 0x15  // length: 16 byte UUID, 2 bytes major&minor, 1 byte RSSI
    
    var uuidBytes = UUID.byteValue
    
    memcpy(&data + 9, &uuidBytes, 16) // UUID
    
    let littleMayor = mayor.littleEndian
    
    data[25] = Byte(truncatingBitPattern: UInt16(littleMayor >> 8) & UInt16(0x00ff))
    data[26] = Byte(truncatingBitPattern: UInt16(littleMayor & 0x00ff))
    
    let littleMinor = minor.littleEndian
    
    data[25] = Byte(truncatingBitPattern: UInt16(littleMinor >> 8) & UInt16(0x00ff))
    data[26] = Byte(truncatingBitPattern: UInt16(littleMinor & 0x00ff))
    
    data[29] = RSSI
    
    let byteTuple: Bluetooth.LowEnergyAdvertisingData = withUnsafePointer(&data) { (pointer) in
        
        let convertedPointer = UnsafePointer<Bluetooth.LowEnergyAdvertisingData>(pointer)
        
        return convertedPointer.memory
    }
    
    return (byteTuple, Byte(length))
}




