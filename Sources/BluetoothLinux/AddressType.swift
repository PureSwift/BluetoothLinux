//
//  AddressType.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// Bluetooth Address type
///
/// - SeeAlso: [Ten Important Differences between Bluetooth BR/EDR and Bluetooth Smart](http://blog.bluetooth.com/ten-important-differences-between-bluetooth-bredr-and-bluetooth-smart/)
public enum AddressType: UInt8 {
    
    /// Bluetooth Basic Rate/Enhanced Data Rate
    case BREDR              = 0x00
    case LowEnergyRandom    = 0x01
    case LowEnergyPublic    = 0x02
    
    public init() { self = BREDR }
    
    /// Whether the Bluetooth address type is LE.
    public var isLowEnergy: Bool {
        
        switch self {
            
        case .LowEnergyPublic, .LowEnergyRandom:
            return true
        
        default:
            return false
        }
    }
}