//
//  BNEPRole.swift
//  BluetoothLinux
//

/// BNEP service role.
///
/// The role of a device in a Bluetooth network encapsulation session,
/// identified by its service class UUID.
public enum BNEPRole: UInt16, CaseIterable, Sendable {

    /// Personal Area Network User
    case personalAreaNetworkUser    = 0x1115

    /// Network Access Point
    case networkAccessPoint         = 0x1116

    /// Group Ad-hoc Network
    case groupNetwork               = 0x1117
}

// MARK: - CustomStringConvertible

extension BNEPRole: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        switch self {
        case .personalAreaNetworkUser:  return "PANU"
        case .networkAccessPoint:       return "NAP"
        case .groupNetwork:             return "GN"
        }
    }

    public var debugDescription: String {
        description
    }
}
