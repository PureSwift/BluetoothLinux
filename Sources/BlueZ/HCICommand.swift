//
//  HCICommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public protocol HCICommand {
    
    /// Opcode Group Field of all commands of this type.
    static var opcodeGroupField: OpcodeGroupField { get }
    
    /// Opcode Command Field of this particular command.
    static var opcodeCommandField: Byte  { get }
    
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
        
        var copy = self
        
        let length = Int(self.dynamicType.dataLength)
        
        var buffer: [UInt8] = [UInt8](count: length, repeatedValue: 0)
        
        memcpy(&buffer, &copy, length)
        
        return Data(byteValue: buffer)
    }
}

// MARK: - C API Extensions

#if os(OSX)
    let OCF_INQUIRY = 0x0001
    struct inquiry_cp {
        var lap: (UInt8, UInt8, UInt8)
        var length: UInt8 /* 1.28s units */
        var num_rsp: UInt8
    }
    let INQUIRY_CP_SIZE = 5
#endif

extension inquiry_cp: HCICommand {
    
    static var opcodeGroupField: OpcodeGroupField { return .LinkControl }
    static var opcodeCommandField: Byte { return Byte(OCF_INQUIRY) }
    static var dataLength: Byte { return Byte(INQUIRY_CP_SIZE) }
}

// TODO: Add extensions (and stubs) for all HCI Command C structs


