//
//  HCIDeviceFlag.swift
//
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth

/// HCI device flags
public struct HCIDeviceFlag: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let up                = HCIDeviceFlag(rawValue: 1 << 0)
    public static let initialized       = HCIDeviceFlag(rawValue: 1 << 1)
    public static let running           = HCIDeviceFlag(rawValue: 1 << 2)

    public static let passiveScan       = HCIDeviceFlag(rawValue: 1 << 3)
    public static let interactiveScan   = HCIDeviceFlag(rawValue: 1 << 4)
    public static let authenticated     = HCIDeviceFlag(rawValue: 1 << 5)
    public static let encrypt           = HCIDeviceFlag(rawValue: 1 << 6)
    public static let inquiry           = HCIDeviceFlag(rawValue: 1 << 7)

    public static let raw               = HCIDeviceFlag(rawValue: 1 << 8)
}

public extension HCIDeviceFlag {

    /// All defined HCI device flags.
    static let all: HCIDeviceFlag = [
        .up, .initialized, .running,
        .passiveScan, .interactiveScan, .authenticated, .encrypt, .inquiry,
        .raw
    ]
}
