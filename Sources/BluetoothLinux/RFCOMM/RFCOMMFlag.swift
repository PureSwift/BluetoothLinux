//
//  File.swift
//
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth

/// RFCOMM Flags
@frozen
public struct RFCOMMFlag: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let reuseDLC          = RFCOMMFlag(rawValue: 0x01) // RFCOMM_REUSE_DLC
    public static let releaseOnHangup   = RFCOMMFlag(rawValue: 0x02) // RFCOMM_RELEASE_ONHUP
    public static let hangupNow         = RFCOMMFlag(rawValue: 0x04) // RFCOMM_HANGUP_NOW
    public static let serialAttached    = RFCOMMFlag(rawValue: 0x08) // RFCOMM_TTY_ATTACHED
}
