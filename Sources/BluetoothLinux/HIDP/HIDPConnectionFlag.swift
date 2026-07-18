//
//  HIDPConnectionFlag.swift
//  BluetoothLinux
//

/// HIDP connection flags.
@frozen
public struct HIDPConnectionFlag: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public extension HIDPConnectionFlag {

    /// Delete the session when the device sends a virtual cable unplug.
    static var virtualCableUnplug: HIDPConnectionFlag { HIDPConnectionFlag(rawValue: 1 << 0) }

    /// Use the boot protocol instead of the report protocol.
    static var bootProtocolMode: HIDPConnectionFlag { HIDPConnectionFlag(rawValue: 1 << 1) }
}
