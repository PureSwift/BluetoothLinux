//
//  RFCOMMLinkMode.swift
//
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth

/// RFCOMM Link Mode
@frozen
public struct RFCOMMLinkMode: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public static let master        = RFCOMMLinkMode(rawValue: 0x0001)
    public static let authenticated = RFCOMMLinkMode(rawValue: 0x0002)
    public static let encrypted     = RFCOMMLinkMode(rawValue: 0x0004)
    public static let trusted       = RFCOMMLinkMode(rawValue: 0x0008)
    public static let reliable      = RFCOMMLinkMode(rawValue: 0x0010)
    public static let secure        = RFCOMMLinkMode(rawValue: 0x0020)
}
