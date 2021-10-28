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
    
    var flags: BitMaskOptionSet<HCIDeviceFlag> {
        var options = BitMaskOptionSet<HCIDeviceFlag>()
        HCIDeviceFlag.allCases.forEach {
            if contains($0) {
                options.insert($0)
            }
        }
        return options
    }
    
    func contains(_ flag: HCIDeviceFlag) -> Bool {
        return (self.rawValue + (UInt32(bitPattern: flag.rawValue) >> 5)) & (1 << (UInt32(bitPattern: flag.rawValue) & 31)) != 0
    }
}
