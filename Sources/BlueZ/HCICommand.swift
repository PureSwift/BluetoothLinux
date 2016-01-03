//
//  HCICommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public protocol HCICommand {
    
    /// Opcode Group Field of all commands of this type.
    static var opcodeGroupField: Bluetooth.OpcodeGroupField { get }
    
    /// Opcode Command Field of this particular command.
    static var opcodeCommandField: Bluetooth.OpcodeCommandField  { get }
    
    /// Length of the command when encoded to data. 
    ///
    /// - Note: Commands are a fixed length.
    static var dataLength: Byte { get }
    
    /// Converts the HCI command to binary data.
    ///
    /// - Precondition: The number of bytes should always be the same as `dataLength`.
    func toData() -> Data
}

public extension HCICommand {
    
    func toData() -> Data {
        
        assert(self as? AnyObject == nil, "The default data encoding implementation for HCICommand only works for value types")
        
        var copy = self
        
        let length = Int(self.dynamicType.dataLength)
        
        var buffer: [UInt8] = [UInt8](count: length, repeatedValue: 0)
        
        memcpy(&buffer, &copy, length)
        
        return Data(byteValue: buffer)
    }
}

// MARK: - C API Extensions

#if os(OSX)
    let OCF_INQUIRY: UInt16 = 0x0001
    struct inquiry_cp {
        var lap: (UInt8, UInt8, UInt8)
        var length: UInt8 /* 1.28s units */
        var num_rsp: UInt8
        init() { stub() }
    }
    let INQUIRY_CP_SIZE = 5
#endif

extension inquiry_cp: HCICommand {
    
    static var opcodeGroupField: Bluetooth.OpcodeGroupField { return .LinkControl }
    static var opcodeCommandField: Bluetooth.OpcodeCommandField { return OCF_INQUIRY }
    static var dataLength: Byte { return Byte(INQUIRY_CP_SIZE) }
}

#if os(OSX)
    let OCF_LE_SET_ADVERTISING_PARAMETERS: UInt16 = 0x0006
    struct le_set_advertising_parameters_cp {
        var min_interval: UInt16
        var max_interval: UInt16
        var advtype: UInt8
        var own_bdaddr_type: UInt8
        var direct_bdaddr_type: UInt8
        var direct_bdaddr: bdaddr_t
        var chan_map: UInt8
        var filter: UInt8
        init() { stub() }
    }
    let LE_SET_ADVERTISING_PARAMETERS_CP_SIZE = 15
#endif

extension le_set_advertising_parameters_cp: HCICommand {
    
    static var opcodeGroupField: Bluetooth.OpcodeGroupField { return .LowEnergy }
    static var opcodeCommandField: Bluetooth.OpcodeCommandField { return OCF_LE_SET_ADVERTISING_PARAMETERS }
    static var dataLength: Byte { return Byte(LE_SET_ADVERTISING_PARAMETERS_CP_SIZE) }
}

#if os(OSX)
    let OCF_LE_SET_ADVERTISE_ENABLE: UInt16 = 0x000A
    struct le_set_advertise_enable_cp {
        var enable: UInt8
        init() { stub() }
    }
    let LE_SET_ADVERTISE_ENABLE_CP_SIZE = 1
#endif

extension le_set_advertise_enable_cp: HCICommand {
    
    static var opcodeGroupField: Bluetooth.OpcodeGroupField { return .LowEnergy }
    static var opcodeCommandField: Bluetooth.OpcodeCommandField { return OCF_LE_SET_ADVERTISE_ENABLE }
    static var dataLength: Byte { return Byte(LE_SET_ADVERTISE_ENABLE_CP_SIZE) }
}

#if os(OSX)
    let OCF_LE_SET_ADVERTISING_DATA: UInt16 = 0x0008
    struct le_set_advertising_data_cp {
        var length: UInt8
        var data: Bluetooth.LowEnergyAdvertisingData
        init() { stub() }
    }
    let LE_SET_ADVERTISING_DATA_CP_SIZE = 32
#endif

extension le_set_advertising_data_cp: HCICommand {
    
    static var opcodeGroupField: Bluetooth.OpcodeGroupField { return .LowEnergy }
    static var opcodeCommandField: Bluetooth.OpcodeCommandField { return OCF_LE_SET_ADVERTISING_DATA }
    static var dataLength: Byte { return Byte(LE_SET_ADVERTISING_DATA_CP_SIZE) }
}

// TODO: Add extensions (and stubs) for all HCI Command C structs


