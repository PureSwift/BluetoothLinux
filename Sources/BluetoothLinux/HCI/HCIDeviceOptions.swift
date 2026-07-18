//
//  HCIDeviceOptions.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth

/// HCI Device Options
public struct HCIDeviceOptions: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public extension HCIDeviceOptions {
    
    var flags: HCIDeviceFlag {
        HCIDeviceFlag(rawValue: rawValue).intersection(.all)
    }

    func contains(_ flag: HCIDeviceFlag) -> Bool {
        HCIDeviceFlag(rawValue: rawValue).isSuperset(of: flag)
    }
}
