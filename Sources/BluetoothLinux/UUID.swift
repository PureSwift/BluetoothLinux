//
//  UUID.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/4/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID

/// Bluetooth UUID
public enum BluetoothUUID {
    
    case Bit16(UInt16)
    case Bit128(SwiftFoundation.UUID)
    
    public var byteValue: [UInt8] {
        
        switch self {
            
        case let .Bit16(value):
            
            let bytes = value.littleEndianBytes
            
            return [bytes.0, bytes.1]
            
        case let .Bit128(value):
            
            let bytes = value.byteValue
            
            return [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7, bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15]
        }
    }
}