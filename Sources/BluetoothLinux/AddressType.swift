//
//  AddressType.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Bluetooth
import BluetoothHCI

/// Bluetooth Address type
///
/// - SeeAlso: [Ten Important Differences between Bluetooth BR/EDR and Bluetooth Smart](http://blog.bluetooth.com/ten-important-differences-between-bluetooth-bredr-and-bluetooth-smart/)
@frozen
public enum AddressType: UInt8 {
    
    /// Bluetooth Basic Rate/Enhanced Data Rate
    case bredr              = 0x00
    case lowEnergyPublic    = 0x01
    case lowEnergyRandom    = 0x02
    
    @_alwaysEmitIntoClient
    public init() { self = .bredr }
}

public extension AddressType {
    
    /// Initialize with LE address type.
    @_alwaysEmitIntoClient
    init(lowEnergy addressType: LowEnergyAddressType) {
        
        switch addressType {
        case .public,
             .publicIdentity:
            self = .lowEnergyPublic
        case .random,
             .randomIdentity:
            self = .lowEnergyRandom
        }
    }
    
    /// Whether the Bluetooth address type is LE.
    @_alwaysEmitIntoClient
    var isLowEnergy: Bool {
        
        switch self {
        case .lowEnergyPublic,
             .lowEnergyRandom:
            return true
        case .bredr:
            return false
        }
    }
}
