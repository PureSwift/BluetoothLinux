//
//  BNEPConnectionFlag.swift
//  BluetoothLinux
//

/// BNEP connection flags.
@frozen
public struct BNEPConnectionFlag: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public extension BNEPConnectionFlag {

    /// The kernel should send the setup connection response.
    ///
    /// When set, the setup connection request has already been received
    /// and the kernel replies to it once the session is created.
    static var setupResponse: BNEPConnectionFlag { BNEPConnectionFlag(rawValue: 1 << 0) }
}
