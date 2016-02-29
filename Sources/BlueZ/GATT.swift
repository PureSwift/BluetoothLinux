//
//  GATT.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// Bluetooth GATT protocol
public struct GATT {
    
    /// GATT Characteristic Properties Bitfield valuess
    public enum CharacteristicProperty: UInt8 {
        
        case Broadcast              = 0x01
        case Read                   = 0x02
        case WriteWithoutResponse   = 0x04
        case Write                  = 0x08
        case Notify                 = 0x10
        case Indicate               = 0x20
        
        /// Characteristic supports write with signature
        case SignedWrite            = 0x40 // BT_GATT_CHRC_PROP_AUTH
        
        case ExtendedProperties     = 0x80
    }
    
    /// GATT Characteristic Extended Properties Bitfield values.
    public enum CharacteristicExtendedProperty: UInt8 {
        
        case ReliableWrite          = 0x01
        
        // TODO: All CharacteristicExtendedProperty
    }
}